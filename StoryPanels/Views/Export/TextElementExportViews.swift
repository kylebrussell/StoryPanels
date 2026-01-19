import SwiftUI

struct TextElementExportView: View {
    let element: TextElement

    var body: some View {
        Group {
            switch element.type {
            case .speechBubble:
                SpeechBubbleExport(text: element.text, size: element.size)
            case .thoughtBubble:
                ThoughtBubbleExport(text: element.text, size: element.size)
            case .caption:
                CaptionExport(text: element.text, size: element.size)
            case .soundEffect:
                SoundEffectExport(text: element.text, size: element.size)
            }
        }
    }
}

struct SpeechBubbleExport: View {
    let text: String
    let size: CGSize

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

            Text(text)
                .font(.system(size: min(14, size.width / 8)))
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.85, height: size.height * 0.7)
                .position(x: size.width / 2, y: size.height / 2)
        }
    }
}

struct ThoughtBubbleExport: View {
    let text: String
    let size: CGSize

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

            Text(text)
                .font(.system(size: min(14, size.width / 8)))
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.7, height: size.height * 0.5)
        }
    }
}

struct CaptionExport: View {
    let text: String
    let size: CGSize

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.yellow.opacity(0.9))
                .frame(width: size.width, height: size.height)
                .overlay(
                    Rectangle()
                        .stroke(Color.black, lineWidth: 2)
                )

            Text(text)
                .font(.system(size: min(12, size.width / 10)))
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.9, height: size.height * 0.8)
        }
    }
}

struct SoundEffectExport: View {
    let text: String
    let size: CGSize

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

            Text(text.uppercased())
                .font(.system(size: min(16, size.width / 6), weight: .bold))
                .multilineTextAlignment(.center)
                .frame(width: size.width * 0.6, height: size.height * 0.4)
        }
        .frame(width: size.width, height: size.height)
    }
}
