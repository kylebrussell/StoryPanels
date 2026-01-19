import SwiftUI

struct CanvasSnapshotView: View {
    let panel: ComicPanelState

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .frame(width: 300, height: 300)

            ForEach(panel.characterStandIns) { character in
                CharacterStandInSnapshotView(character: character)
                    .position(character.position)
            }

            ForEach(panel.textElements) { element in
                TextElementSnapshotView(element: element)
                    .position(element.position)
            }
        }
        .frame(width: 300, height: 300)
    }
}

struct CharacterStandInSnapshotView: View {
    let character: CharacterStandIn

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.7))
                .frame(width: character.size.width, height: character.size.height)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )

            Text("\(character.number)")
                .font(.system(size: min(24, character.size.width / 3), weight: .bold))
                .foregroundColor(.white)

            if !character.label.isEmpty {
                Text(character.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
                    .offset(y: character.size.height / 2 + 15)
            }
        }
    }
}

struct TextElementSnapshotView: View {
    let element: TextElement

    var body: some View {
        TextElementExportView(element: element)
    }
}
