import SwiftUI

/// Centralized colors & modifiers to give the app a fun comic-book vibe.
enum ComicTheme {
    /// A light off-white, reminiscent of comic book paper.
    static let background = Color(red: 0.98, green: 0.95, blue: 0.85)
    /// A bright red that will be used for primary actions and accents.
    static let primary = Color.red
    /// A punchy yellow for secondary accents.
    static let secondary = Color.yellow
}

/// Reusable button style that mimics thick inked outlines often seen in comics.
struct ComicButtonStyle: ButtonStyle {
    var backgroundColor: Color = ComicTheme.secondary
    var foregroundColor: Color = .black
    var strokeColor: Color = .black

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(strokeColor, lineWidth: 3)
            )
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}
