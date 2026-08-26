import Foundation

struct Track: Identifiable, Equatable {
    let id: String          // YouTube video ID
    let title: String
    let channel: String
    let duration: TimeInterval
    let thumbnailURL: URL?

    var durationFormatted: String {
        Self.format(duration)
    }

    static func format(_ seconds: TimeInterval) -> String {
        let s = max(0, Int(seconds))
        let h = s / 3600
        let m = (s % 3600) / 60
        let sec = s % 60
        if h > 0 {
            return "\(h):\(String(format: "%02d", m)):\(String(format: "%02d", sec))"
        }
        return "\(m):\(String(format: "%02d", sec))"
    }
}

extension Track {
    static let preview = Track(
        id: "dQw4w9WgXcQ",
        title: "Designing for the desktop — a talk on native app craft",
        channel: "Interface Notes",
        duration: 754,
        thumbnailURL: nil
    )
}
