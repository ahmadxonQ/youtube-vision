import SwiftUI

// MARK: - Color Theme

enum ColorTheme: String, CaseIterable {
    case classic    = "Classic"
    case blue       = "Blue"
    case crimson    = "Crimson"
    case sky        = "Sky"
    case green      = "Green"

    var accent: Color {
        switch self {
        case .classic:  return Color(hex: 0xE5484D)
        case .blue:     return Color(hex: 0x2196F3)
        case .crimson:  return Color(hex: 0x8B1E2D)
        case .sky:      return Color(hex: 0x3A86FF)
        case .green:    return Color(hex: 0x1DB954)
        }
    }

    var accentSecondary: Color { accent }

    var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accent], startPoint: .leading, endPoint: .trailing)
    }

    var waveColors: [Color] {
        [accent, accent, accent, accent]
    }
}

// MARK: - Theme Manager

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var current: ColorTheme {
        didSet {
            UserDefaults.standard.set(current.rawValue, forKey: "colorTheme")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "colorTheme") ?? ""
        self.current = ColorTheme(rawValue: saved) ?? .classic
    }
}

// MARK: - VisionTheme (static palette + dynamic accent)

enum VisionTheme {
    // MARK: - Dark palette
    static let surface        = Color(hex: 0x16191E)
    static let surfaceAlt     = Color(hex: 0x1E232A)
    static let border         = Color(hex: 0x2A3039)
    static let textPrimary    = Color(hex: 0xE6E9EE)
    static let textMuted      = Color(hex: 0x8792A0)
    static let background     = Color(hex: 0x0A0C0F)

    @MainActor static var accent: Color { ThemeManager.shared.current.accent }
    @MainActor static var accentSecondary: Color { ThemeManager.shared.current.accentSecondary }
    @MainActor static var accentGradient: LinearGradient { ThemeManager.shared.current.accentGradient }

    static let accentHover    = Color(hex: 0xF06A6E)

    // MARK: - Dimensions
    static let barWidth: CGFloat       = 540
    static let barCornerRadius: CGFloat = 11
    static let controlSize: CGFloat    = 32
    static let avatarSize: CGFloat     = 28
    static let progressHeight: CGFloat = 3

    // MARK: - Fonts
    static let mono = Font.custom("JetBrains Mono", size: 10)
    static let monoSmall = Font.custom("JetBrains Mono", size: 9)
    static let monoLabel = Font.custom("JetBrains Mono", size: 11)
    static let titleFont = Font.custom("Space Grotesk", size: 13).weight(.semibold)
    static let bodyFont = Font.custom("Space Grotesk", size: 12)

    static let monoFallback = Font.system(size: 10, design: .monospaced)
    static let titleFallback = Font.system(size: 13, weight: .semibold, design: .default)
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
