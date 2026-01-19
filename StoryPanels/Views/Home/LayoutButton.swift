import SwiftUI

struct LayoutButton: View {
    let layout: PanelLayout
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(0..<layout.panelCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(isSelected ? ComicTheme.accent.opacity(0.25) : ComicTheme.secondarySurface)
                            .frame(width: layout == .single ? 60 : 30, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .stroke(ComicTheme.outline, lineWidth: ComicTheme.Metrics.outlineWidth)
                            )
                    }
                }

                Text(layout.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .padding(12)
            .background(ComicTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: ComicTheme.Metrics.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: ComicTheme.Metrics.cornerRadius, style: .continuous)
                    .stroke(
                        isSelected ? ComicTheme.accent : ComicTheme.outline,
                        lineWidth: isSelected ? ComicTheme.Metrics.selectedOutlineWidth : ComicTheme.Metrics.outlineWidth
                    )
            )
            .shadow(color: ComicTheme.subtleShadow, radius: 2, x: 0, y: 1)
        }
    }
}
