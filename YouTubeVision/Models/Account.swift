import SwiftUI

struct GoogleAccount: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let email: String
    let avatarURL: URL?

    var initial: String {
        String(name.prefix(1)).uppercased()
    }

    var color: Color {
        let colors: [Color] = [
            Color(hex: 0xE5484D),
            Color(hex: 0x3B82F6),
            Color(hex: 0x12A594),
            Color(hex: 0xF5A524),
            Color(hex: 0x8B5CF6)
        ]
        let hash = abs(email.hashValue)
        return colors[hash % colors.count]
    }
}

// MARK: - Preview / mock data

extension GoogleAccount {
    static let preview = GoogleAccount(
        id: "1",
        name: "Ahmadxon Qodirov",
        email: "ahmadxon@gmail.com",
        avatarURL: nil
    )

    static let previewList: [GoogleAccount] = [
        GoogleAccount(id: "1", name: "Ahmadxon Qodirov", email: "ahmadxon@gmail.com", avatarURL: nil),
        GoogleAccount(id: "2", name: "Work Account", email: "a.qodirov@msagroup.com", avatarURL: nil),
        GoogleAccount(id: "3", name: "Music Channel", email: "music@gmail.com", avatarURL: nil)
    ]
}
