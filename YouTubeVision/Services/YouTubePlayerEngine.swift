import AppKit
import Combine

/// Controls YouTube playback in Chrome via AppleScript.
/// No WKWebView — audio comes from Chrome, this is a remote control.
@MainActor
final class YouTubePlayerEngine: NSObject, ObservableObject {

    // MARK: - Published state

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var videoTitle: String = ""
    @Published var volume: Double = 72
    @Published var speed: Double = 1.0
    @Published var isReady = false
    @Published var videoID: String = ""

    // MARK: - Private

    private var pollTimer: Timer?

    // MARK: - Setup

    override init() {
        super.init()
    }

    func startPolling() {
        guard pollTimer == nil else { return }
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
        isReady = true
        print("[YTEngine] Polling Chrome started")
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    // MARK: - Poll Chrome

    private func poll() {
        let js = """
        (function(){
            var v = document.querySelector('video');
            if (!v) return JSON.stringify({error:'no video'});
            var u = new URL(location.href);
            return JSON.stringify({
                currentTime: v.currentTime,
                duration: v.duration || 0,
                paused: v.paused,
                volume: v.volume * 100,
                speed: v.playbackRate,
                vid: u.searchParams.get('v') || '',
                title: document.title.replace(/ - YouTube$/, '').replace(/^\\(\\d+\\)\\s*/, '')
            });
        })()
        """

        chromeExecJS(js) { [weak self] result in
            guard let self, let result else { return }

            guard let data = result.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  dict["error"] == nil else { return }

            Task { @MainActor [weak self] in
                guard let self else { return }

                if let time = dict["currentTime"] as? Double {
                    self.currentTime = time
                }
                if let dur = dict["duration"] as? Double, dur > 0, !dur.isNaN {
                    self.duration = dur
                }
                if let paused = dict["paused"] as? Bool {
                    self.isPlaying = !paused
                }
                if let vol = dict["volume"] as? Double {
                    self.volume = vol
                }
                if let spd = dict["speed"] as? Double {
                    self.speed = spd
                }
                if let title = dict["title"] as? String, !title.isEmpty, title != "YouTube" {
                    self.videoTitle = title
                }
                if let vid = dict["vid"] as? String, !vid.isEmpty {
                    self.videoID = vid
                }
            }
        }
    }

    // MARK: - Playback controls

    func togglePlayPause() {
        chromeExecJS("(function(){ var v=document.querySelector('video'); if(v){ v.paused ? v.play() : v.pause(); } })()")
    }

    func play() {
        chromeExecJS("document.querySelector('video')?.play()")
    }

    func pause() {
        chromeExecJS("document.querySelector('video')?.pause()")
    }

    func nextVideo() {
        // If in a playlist/mix, use YouTube's next button (follows playlist order).
        // Otherwise, click the first suggested video in the sidebar.
        chromeExecJS("""
        (function(){
            var list = new URL(location.href).searchParams.get('list');
            if (list) {
                var b = document.querySelector('.ytp-next-button');
                if (b) { b.click(); return; }
            }
            var s = document.querySelector('ytd-watch-next-secondary-results-renderer a');
            if (s) s.click();
        })()
        """)
    }

    func previousVideo() {
        chromeExecJS("""
        (function(){
            var v = document.querySelector('video');
            if (v && v.currentTime > 3) { v.currentTime = 0; }
            else { var b = document.querySelector('.ytp-prev-button'); if(b) b.click(); else history.back(); }
        })()
        """)
    }

    func seek(to fraction: Double) {
        let seconds = fraction * duration
        chromeExecJS("(function(){ var v=document.querySelector('video'); if(v) v.currentTime=\(seconds); })()")
    }

    func setVolume(_ vol: Double) {
        volume = vol
        chromeExecJS("(function(){ var v=document.querySelector('video'); if(v) v.volume=\(vol / 100.0); })()")
    }

    func setSpeed(_ spd: Double) {
        speed = spd
        chromeExecJS("(function(){ var v=document.querySelector('video'); if(v) v.playbackRate=\(spd); })()")
    }

    // MARK: - AppleScript bridge

    private func chromeExecJS(_ js: String, completion: ((String?) -> Void)? = nil) {
        let escapedJS = js
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let script = """
        tell application "Google Chrome"
            set ytTab to missing value
            repeat with w in windows
                repeat with t in tabs of w
                    if URL of t contains "youtube.com/watch" then
                        set ytTab to t
                        exit repeat
                    end if
                end repeat
                if ytTab is not missing value then exit repeat
            end repeat
            if ytTab is missing value then return "no_tab"
            return execute ytTab javascript "\(escapedJS)"
        end tell
        """

        DispatchQueue.global(qos: .userInitiated).async {
            let appleScript = NSAppleScript(source: script)
            var errorInfo: NSDictionary?
            let result = appleScript?.executeAndReturnError(&errorInfo)

            if let errorInfo {
                print("[YTEngine] AppleScript error: \(errorInfo)")
            }

            let output = result?.stringValue
            if let completion {
                DispatchQueue.main.async {
                    completion(output)
                }
            }
        }
    }
}
