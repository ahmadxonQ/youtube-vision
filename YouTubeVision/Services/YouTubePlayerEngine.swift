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
        enableAppleScriptForBrowsers()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
        isReady = true
        print("[YTEngine] Polling started")
    }

    /// Auto-enable "Allow JavaScript from Apple Events" for all installed browsers.
    /// Uses `defaults write <bundleID> AppleScriptEnabled -bool true` via UserDefaults.
    private func enableAppleScriptForBrowsers() {
        for browser in Self.browserBundleIDs {
            // Only write if the app is installed (has a bundle on disk)
            guard NSWorkspace.shared.urlForApplication(withBundleIdentifier: browser.bundleID) != nil else {
                continue
            }
            if let prefs = UserDefaults(suiteName: browser.bundleID) {
                if prefs.bool(forKey: "AppleScriptEnabled") == false {
                    prefs.set(true, forKey: "AppleScriptEnabled")
                    print("[YTEngine] Enabled AppleScript for \(browser.name)")
                }
            }
        }
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

        browserExecJS(js) { [weak self] result in
            guard let self else { return }

            // If poll fails (Chrome not responding, no tab, etc.) → mark as not playing
            guard let result,
                  let data = result.data(using: .utf8),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  dict["error"] == nil else {
                Task { @MainActor [weak self] in
                    self?.isPlaying = false
                }
                return
            }

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
        browserExecJS("(function(){ var v=document.querySelector('video'); if(v){ v.paused ? v.play() : v.pause(); } })()")
    }

    func play() {
        browserExecJS("document.querySelector('video')?.play()")
    }

    func pause() {
        browserExecJS("document.querySelector('video')?.pause()")
    }

    func nextVideo() {
        // If in a playlist/mix, use YouTube's next button (follows playlist order).
        // Otherwise, click the first suggested video in the sidebar.
        browserExecJS("""
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
        browserExecJS("""
        (function(){
            var v = document.querySelector('video');
            if (v && v.currentTime > 3) { v.currentTime = 0; }
            else { var b = document.querySelector('.ytp-prev-button'); if(b) b.click(); else history.back(); }
        })()
        """)
    }

    func seek(to fraction: Double) {
        let seconds = fraction * duration
        browserExecJS("(function(){ var v=document.querySelector('video'); if(v) v.currentTime=\(seconds); })()")
    }

    func setVolume(_ vol: Double) {
        volume = vol
        browserExecJS("(function(){ var v=document.querySelector('video'); if(v) v.volume=\(vol / 100.0); })()")
    }

    func setSpeed(_ spd: Double) {
        speed = spd
        browserExecJS("(function(){ var v=document.querySelector('video'); if(v) v.playbackRate=\(spd); })()")
    }

    // MARK: - Supported browsers (Chromium-based, same AppleScript API)

    /// Browser display name → bundle identifier (for auto-enabling AppleScript)
    private static let browserBundleIDs: [(name: String, bundleID: String)] = [
        ("Google Chrome",   "com.google.Chrome"),
        ("Brave Browser",   "com.brave.Browser"),
        ("Microsoft Edge",  "com.microsoft.edgemac"),
        ("Arc",             "company.thebrowser.Browser"),
        ("Yandex",          "ru.yandex.desktop.browser"),
        ("Opera",           "com.operasoftware.Opera"),
        ("Vivaldi",         "com.vivaldi.Vivaldi"),
        ("Chromium",        "org.chromium.Chromium")
    ]

    private static let browsers = browserBundleIDs.map(\.name)

    /// The browser we last found a YouTube tab in — skip scanning all browsers every poll.
    private var activeBrowser: String?

    // MARK: - AppleScript bridge

    /// Returns the names of supported browsers that are currently running.
    private func runningBrowsers() -> [String] {
        let names = Self.browsers.map { "\"\($0)\"" }.joined(separator: ", ")
        let script = """
        tell application "System Events"
            set running_list to {}
            repeat with b in {\(names)}
                if exists process b then set end of running_list to b
            end repeat
            return running_list
        end tell
        """
        let appleScript = NSAppleScript(source: script)
        var errorInfo: NSDictionary?
        guard let result = appleScript?.executeAndReturnError(&errorInfo) else { return [] }

        // Result is an AppleScript list — extract each item
        var found: [String] = []
        for i in 1...result.numberOfItems {
            if let name = result.atIndex(i)?.stringValue {
                found.append(name)
            }
        }
        return found
    }

    private func browserExecJS(_ js: String, completion: ((String?) -> Void)? = nil) {
        let escapedJS = js
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }

            // Only check browsers that are actually running (avoids "locate app" dialogs)
            var running = self.runningBrowsers()
            if running.isEmpty {
                if let completion {
                    DispatchQueue.main.async { completion(nil) }
                }
                return
            }

            // Try the cached active browser first
            if let active = self.activeBrowser, running.contains(active) {
                running = [active] + running.filter { $0 != active }
            }

            for browser in running {
                let script = """
                tell application "\(browser)"
                    set playingTab to missing value
                    set firstTab to missing value
                    repeat with w in windows
                        repeat with t in tabs of w
                            if URL of t contains "youtube.com/watch" then
                                if firstTab is missing value then set firstTab to t
                                set isPlaying to execute t javascript "!document.querySelector('video')?.paused"
                                if isPlaying is "true" then
                                    set playingTab to t
                                    exit repeat
                                end if
                            end if
                        end repeat
                        if playingTab is not missing value then exit repeat
                    end repeat
                    set ytTab to playingTab
                    if ytTab is missing value then set ytTab to firstTab
                    if ytTab is missing value then return "no_tab"
                    return execute ytTab javascript "\(escapedJS)"
                end tell
                """

                let appleScript = NSAppleScript(source: script)
                var errorInfo: NSDictionary?
                let result = appleScript?.executeAndReturnError(&errorInfo)
                let output = result?.stringValue

                if output == "no_tab" { continue }

                if let errorInfo {
                    print("[YTEngine] \(browser) error: \(errorInfo)")
                    continue
                }

                // Found a YouTube tab in this browser — cache it
                DispatchQueue.main.async { [weak self] in
                    self?.activeBrowser = browser
                }

                if let completion {
                    DispatchQueue.main.async { completion(output) }
                }
                return
            }

            // No browser had a YouTube tab
            if let completion {
                DispatchQueue.main.async { completion(nil) }
            }
        }
    }
}
