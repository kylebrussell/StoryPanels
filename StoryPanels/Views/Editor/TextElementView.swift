import SwiftUI

struct TextElementView: View {
    @Binding var element: TextElement
    let onDelete: () -> Void
    let onTextElementInteraction: () -> Void
    let onInteractionFinished: () -> Void
    @State private var dragOffset = CGSize.zero
    @GestureState private var isDragging = false
    @GestureState private var magnification: CGFloat = 1.0

    var body: some View {
        Group {
            switch element.type {
            case .speechBubble:
                SpeechBubbleView(
                    text: $element.text,
                    isEditing: $element.isEditing,
                    size: element.size,
                    onTextElementInteraction: onTextElementInteraction,
                    onEditingFinished: onInteractionFinished
                )
            case .thoughtBubble:
                ThoughtBubbleView(
                    text: $element.text,
                    isEditing: $element.isEditing,
                    size: element.size,
                    onTextElementInteraction: onTextElementInteraction,
                    onEditingFinished: onInteractionFinished
                )
            case .caption:
                CaptionView(
                    text: $element.text,
                    isEditing: $element.isEditing,
                    size: element.size,
                    onTextElementInteraction: onTextElementInteraction,
                    onEditingFinished: onInteractionFinished
                )
            case .soundEffect:
                SoundEffectView(
                    text: $element.text,
                    isEditing: $element.isEditing,
                    size: element.size,
                    onTextElementInteraction: onTextElementInteraction,
                    onEditingFinished: onInteractionFinished
                )
            }
        }
        .scaleEffect(magnification)
        .position(
            x: element.position.x + dragOffset.width,
            y: element.position.y + dragOffset.height
        )
        .gesture(
            SimultaneousGesture(
                DragGesture()
                    .updating($isDragging) { _, state, _ in
                        state = true
                    }
                    .onChanged { value in
                        dragOffset = value.translation
                        onTextElementInteraction()
                    }
                    .onEnded { value in
                        element.position.x += value.translation.width
                        element.position.y += value.translation.height
                        dragOffset = .zero
                        onInteractionFinished()
                    },
                MagnificationGesture()
                    .updating($magnification) { value, state, _ in
                        state = value
                        onTextElementInteraction()
                    }
                    .onEnded { value in
                        let newWidth = max(60, min(300, element.size.width * value))
                        let newHeight = max(30, min(200, element.size.height * value))
                        element.size = CGSize(width: newWidth, height: newHeight)
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

struct SpeechBubbleView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let size: CGSize
    let onTextElementInteraction: () -> Void
    let onEditingFinished: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .frame(width: size.width, height: size.height)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 2)
                )

            Path { path in
                path.move(to: CGPoint(x: size.width * 0.33, y: size.height))
                path.addLine(to: CGPoint(x: size.width * 0.25, y: size.height + 20))
                path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
            }
            .fill(Color.white)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: size.width * 0.33, y: size.height))
                    path.addLine(to: CGPoint(x: size.width * 0.25, y: size.height + 20))
                    path.addLine(to: CGPoint(x: size.width * 0.5, y: size.height))
                }
                .stroke(Color.black, lineWidth: 2)
            )

            Group {
                if isEditing {
                    TextField("Enter text", text: $text, onCommit: {
                        isEditing = false
                        onEditingFinished()
                    })
                } else {
                    Text(text.isEmpty ? "Tap to edit" : text)
                        .font(.system(size: min(14, size.width / 8)))
                        .onTapGesture {
                            isEditing = true
                            onTextElementInteraction()
                        }
                }
            }
            .multilineTextAlignment(.center)
            .frame(width: size.width * 0.85, height: size.height * 0.7)
            .position(x: size.width / 2, y: size.height / 2)
        }
    }
}

struct ThoughtBubbleView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let size: CGSize
    let onTextElementInteraction: () -> Void
    let onEditingFinished: () -> Void

    var body: some View {
        ZStack {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: size.width, height: size.height * 0.8)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))

                Circle()
                    .fill(Color.white)
                    .frame(width: size.width * 0.3, height: size.height * 0.3)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -size.width * 0.35, y: size.height * 0.25)

                Circle()
                    .fill(Color.white)
                    .frame(width: size.width * 0.2, height: size.height * 0.2)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                    .offset(x: -size.width * 0.45, y: size.height * 0.45)
            }

            if isEditing {
                TextField("Enter thought", text: $text, onCommit: {
                    isEditing = false
                    onEditingFinished()
                })
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.7, height: size.height * 0.5)
                .font(.system(size: min(14, size.width / 8)))
            } else {
                Text(text.isEmpty ? "Tap to edit" : text)
                    .font(.system(size: min(14, size.width / 8)))
                    .multilineTextAlignment(.center)
                    .frame(width: size.width * 0.7, height: size.height * 0.5)
                    .onTapGesture {
                        isEditing = true
                        onTextElementInteraction()
                    }
            }
        }
    }
}

struct CaptionView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let size: CGSize
    let onTextElementInteraction: () -> Void
    let onEditingFinished: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: size.width, height: size.height)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )

            if isEditing {
                TextField("Enter caption", text: $text, onCommit: {
                    isEditing = false
                    onEditingFinished()
                })
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.9, height: size.height * 0.8)
                .font(.system(size: min(12, size.width / 10)))
            } else {
                Text(text.isEmpty ? "Tap to edit" : text)
                    .font(.system(size: min(12, size.width / 10)))
                    .multilineTextAlignment(.center)
                    .frame(width: size.width * 0.9, height: size.height * 0.8)
                    .onTapGesture {
                        isEditing = true
                        onTextElementInteraction()
                    }
            }
        }
    }
}

struct SoundEffectView: View {
    @Binding var text: String
    @Binding var isEditing: Bool
    let size: CGSize
    let onTextElementInteraction: () -> Void
    let onEditingFinished: () -> Void

    var body: some View {
        ZStack {
            ForEach(0..<8) { i in
                Rectangle()
                    .fill(Color.orange)
                    .frame(width: size.width * 1.2, height: size.height * 0.2)
                    .rotationEffect(.degrees(Double(i) * 45))
            }

            Circle()
                .fill(Color.yellow)
                .frame(width: size.width * 0.8, height: size.height * 0.8)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 3)
                )

            if isEditing {
                TextField("BOOM!", text: $text, onCommit: {
                    isEditing = false
                    onEditingFinished()
                })
                .multilineTextAlignment(.center)
                .font(.system(size: min(16, size.width / 6), weight: .bold))
                .frame(width: size.width * 0.6, height: size.height * 0.4)
            } else {
                Text(text.isEmpty ? "TAP!" : text.uppercased())
                    .font(.system(size: min(16, size.width / 6), weight: .bold))
                    .multilineTextAlignment(.center)
                    .frame(width: size.width * 0.6, height: size.height * 0.4)
                    .onTapGesture {
                        isEditing = true
                        onTextElementInteraction()
                    }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
