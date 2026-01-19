import SwiftUI
import UIKit

/// Centralized colors & modifiers to give the app a fun comic-book vibe while remaining HIG-friendly.
enum ComicTheme {
    static let accent = Color(uiColor: .systemRed)

    static let paperBackground = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.11, green: 0.10, blue: 0.10, alpha: 1.0)
        }
        return UIColor(red: 0.98, green: 0.95, blue: 0.89, alpha: 1.0)
    })

    static let surface = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.16, green: 0.15, blue: 0.14, alpha: 1.0)
        }
        return UIColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1.0)
    })

    static let secondarySurface = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.20, green: 0.19, blue: 0.18, alpha: 1.0)
        }
        return UIColor(red: 0.97, green: 0.94, blue: 0.90, alpha: 1.0)
    })

    static let outline = Color(uiColor: .separator)
    static let subtleShadow = Color.black.opacity(0.12)

    enum Metrics {
        static let cornerRadius: CGFloat = 12
        static let largeCornerRadius: CGFloat = 16
        static let outlineWidth: CGFloat = 1
        static let selectedOutlineWidth: CGFloat = 2
        static let panelSize: CGFloat = 300
        static let panelInset: CGFloat = 8
        static let sectionSpacing: CGFloat = 16
        static let controlSpacing: CGFloat = 12
    }
}

/// Reusable button style with lighter outlines and clearer hierarchy.
struct ComicButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
        case destructive
        case subtle
    }

    var variant: Variant = .secondary
    var isCompact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        let cornerRadius = isCompact ? ComicTheme.Metrics.cornerRadius : ComicTheme.Metrics.largeCornerRadius

        return configuration.label
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.vertical, isCompact ? 8 : 12)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }

    private var backgroundColor: Color {
        switch variant {
        case .primary:
            return ComicTheme.accent
        case .secondary:
            return ComicTheme.surface
        case .destructive:
            return Color(uiColor: .systemRed).opacity(0.15)
        case .subtle:
            return Color.clear
        }
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .white
        case .secondary:
            return .primary
        case .destructive:
            return Color(uiColor: .systemRed)
        case .subtle:
            return .primary
        }
    }

    private var borderColor: Color {
        switch variant {
        case .primary:
            return ComicTheme.accent.opacity(0.6)
        case .secondary:
            return ComicTheme.outline
        case .destructive:
            return Color(uiColor: .systemRed).opacity(0.6)
        case .subtle:
            return ComicTheme.outline
        }
    }

    private var borderWidth: CGFloat {
        switch variant {
        case .subtle:
            return ComicTheme.Metrics.outlineWidth
        default:
            return ComicTheme.Metrics.outlineWidth
        }
    }

    private var shadowColor: Color {
        switch variant {
        case .subtle:
            return .clear
        default:
            return ComicTheme.subtleShadow
        }
    }
}
