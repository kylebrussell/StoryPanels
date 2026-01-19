import SwiftUI

struct PanelView: View {
    @Binding var panel: ComicPanelState
    let isSelected: Bool
    let onTextElementInteraction: (Int) -> Void
    let onCharacterInteraction: (Int) -> Void
    let onInteractionFinished: () -> Void

    var body: some View {
        let panelSize = ComicTheme.Metrics.panelSize
        let panelInset = ComicTheme.Metrics.panelInset
        let cornerRadius = ComicTheme.Metrics.largeCornerRadius
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(ComicTheme.surface)
                .frame(width: panelSize, height: panelSize)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            isSelected ? ComicTheme.accent : ComicTheme.outline,
                            lineWidth: isSelected ? ComicTheme.Metrics.selectedOutlineWidth : ComicTheme.Metrics.outlineWidth
                        )
                )
                .shadow(
                    color: isSelected ? ComicTheme.accent.opacity(0.2) : ComicTheme.subtleShadow,
                    radius: 4,
                    x: 0,
                    y: 2
                )

            if let image = panel.generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: panelSize - (panelInset * 2), height: panelSize - (panelInset * 2))
                    .clipped()
                    .cornerRadius(ComicTheme.Metrics.cornerRadius)
            } else if panel.isGenerating {
                ProgressView("Generating...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    Text("Tap to select")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(panel.characterStandIns.indices, id: \.self) { index in
                CharacterStandInView(
                    character: $panel.characterStandIns[index],
                    onDelete: {
                        panel.characterStandIns.remove(at: index)
                        onInteractionFinished()
                    },
                    onCharacterInteraction: {
                        onCharacterInteraction(index)
                    },
                    onInteractionFinished: onInteractionFinished
                )
            }

            ForEach(panel.textElements.indices, id: \.self) { index in
                TextElementView(
                    element: $panel.textElements[index],
                    onDelete: {
                        panel.textElements.remove(at: index)
                        onInteractionFinished()
                    },
                    onTextElementInteraction: {
                        onTextElementInteraction(index)
                    },
                    onInteractionFinished: onInteractionFinished
                )
            }
        }
        .frame(width: panelSize, height: panelSize)
    }
}
