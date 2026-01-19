import SwiftUI

struct StyleTheme: Identifiable, Equatable {
    let id: UUID
    let name: String
    let promptModifier: String

    init(id: UUID = UUID(), name: String, promptModifier: String) {
        self.id = id
        self.name = name
        self.promptModifier = promptModifier
    }

    static let allThemes: [StyleTheme] = [
        StyleTheme(name: "Classic", promptModifier: "illustrated in vibrant Golden Age comic book style with bold lines"),
        StyleTheme(name: "Manga", promptModifier: "in highly detailed manga style with expressive characters"),
        StyleTheme(name: "Noir", promptModifier: "in moody black-and-white noir style with dramatic shadows"),
        StyleTheme(name: "Sci-Fi", promptModifier: "in sleek futuristic sci-fi style with glowing tech")
    ]

    static let defaultTheme = StyleTheme.allThemes.first!

    static func theme(named name: String) -> StyleTheme {
        StyleTheme.allThemes.first { $0.name == name } ?? StyleTheme.defaultTheme
    }

    static func == (lhs: StyleTheme, rhs: StyleTheme) -> Bool {
        lhs.name == rhs.name
    }
}
