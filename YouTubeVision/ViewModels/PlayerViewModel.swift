import SwiftUI
import Combine

@MainActor
final class PlayerViewModel: ObservableObject {

    // MARK: - Player engine

    private var engine: YouTubePlayerEngine?

    // MARK: - UI state

    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Double = 72
    @Published var speed: Double = 1.0

    @Published var currentTrack: Track?

    // MARK: - Computed

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var currentTimeFormatted: String {
        Track.format(currentTime)
    }

    var durationFormatted: String {
        Track.format(duration)
    }

    var speedLabel: String {
        if speed == floor(speed) { return "\(Int(speed))×" }
        return "\(speed)×"
    }

    static let availableSpeeds: [Double] = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

    // MARK: - Subscriptions

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Engine lifecycle

    func startEngine() {
        guard engine == nil else { return }
        let eng = YouTubePlayerEngine()
        engine = eng

        eng.$isPlaying
            .receive(on: RunLoop.main)
            .assign(to: &$isPlaying)

        eng.$currentTime
            .receive(on: RunLoop.main)
            .assign(to: &$currentTime)

        eng.$duration
            .receive(on: RunLoop.main)
            .assign(to: &$duration)

        eng.$volume
            .receive(on: RunLoop.main)
            .assign(to: &$volume)

        eng.$speed
            .receive(on: RunLoop.main)
            .assign(to: &$speed)

        eng.$videoTitle
            .receive(on: RunLoop.main)
            .sink { [weak self] title in
                guard let self, !title.isEmpty else { return }
                self.currentTrack = Track(
                    id: eng.videoID,
                    title: title,
                    channel: "",
                    duration: eng.duration,
                    thumbnailURL: nil
                )
            }
            .store(in: &cancellables)

        eng.$videoID
            .receive(on: RunLoop.main)
            .sink { [weak self] vid in
                guard let self, !vid.isEmpty, let track = self.currentTrack, track.id != vid else { return }
                self.currentTrack = Track(
                    id: vid,
                    title: track.title,
                    channel: "",
                    duration: eng.duration,
                    thumbnailURL: nil
                )
            }
            .store(in: &cancellables)

        // Browser closed or the YouTube tab went away → drop back to the empty state.
        eng.$hasTab
            .receive(on: RunLoop.main)
            .sink { [weak self] hasTab in
                guard let self, !hasTab else { return }
                self.currentTrack = nil
                self.currentTime = 0
                self.duration = 0
            }
            .store(in: &cancellables)

        eng.startPolling()
    }

    // MARK: - Playback controls

    func togglePlay() {
        engine?.togglePlayPause()
    }

    func cycleSpeed() {
        let speeds = Self.availableSpeeds
        if let idx = speeds.firstIndex(of: speed) {
            speed = speeds[(idx + 1) % speeds.count]
        } else {
            speed = 1.0
        }
        engine?.setSpeed(speed)
    }

    func seek(to fraction: Double) {
        engine?.seek(to: fraction)
    }

    func previousTrack() {
        engine?.previousVideo()
    }

    func nextTrack() {
        engine?.nextVideo()
    }

    func setVolume(_ vol: Double) {
        volume = vol
        engine?.setVolume(vol)
    }

    func toggleMute() {
        if volume > 0 {
            volume = 0
        } else {
            volume = 72
        }
        engine?.setVolume(volume)
    }
}
