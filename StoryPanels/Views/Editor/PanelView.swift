import SwiftUI

struct PanelView: View {
    @Binding var panel: ComicPanelState
    let isSelected: Bool
    let onTextElementInteraction: (Int) -> Void
    let onCharacterInteraction: (Int) -> Void
    let onInteractionFinished: () -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(width: 300, height: 300)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: isSelected ? 5 : 3)
                )
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 2, y: 2)

            if let image = panel.generatedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 290, height: 290)
                    .clipped()
                    .cornerRadius(8)
            } else if panel.isGenerating {
                ProgressView("Generating...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Tap to select")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.5))
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
        .frame(width: 300, height: 300)
    }
}
