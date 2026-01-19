import SwiftUI

struct CharacterStandInView: View {
    @Binding var character: CharacterStandIn
    let onDelete: () -> Void
    let onCharacterInteraction: () -> Void
    let onInteractionFinished: () -> Void
    @State private var dragOffset = CGSize.zero
    @GestureState private var isDragging = false
    @GestureState private var magnification: CGFloat = 1.0

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
        .scaleEffect(magnification)
        .position(
            x: character.position.x + dragOffset.width,
            y: character.position.y + dragOffset.height
        )
        .gesture(
            SimultaneousGesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        dragOffset = value.translation
                        onCharacterInteraction()
                    }
                    .onEnded { value in
                        character.position.x += value.translation.width
                        character.position.y += value.translation.height
                        dragOffset = .zero
                        onInteractionFinished()
                    },
                MagnificationGesture()
                    .updating($magnification) { value, state, _ in
                        state = value
                        onCharacterInteraction()
                    }
                    .onEnded { value in
                        let newSize = max(40, min(120, character.size.width * value))
                        character.size = CGSize(width: newSize, height: newSize)
                        onInteractionFinished()
                    }
            )
        )
        .contextMenu {
            Button(action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
        .scaleEffect(isDragging ? 1.1 : 1.0)
        .animation(.spring(response: 0.3), value: isDragging)
        .animation(.spring(response: 0.3), value: magnification)
    }
}
