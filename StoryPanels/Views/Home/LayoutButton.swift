import SwiftUI

struct LayoutButton: View {
    let layout: PanelLayout
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                HStack(spacing: 4) {
                    ForEach(0..<layout.panelCount, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(isSelected ? ComicTheme.primary : ComicTheme.secondary.opacity(0.4))
                            .frame(width: layout == .single ? 60 : 30, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.black, lineWidth: 2)
                            )
                    }
                }

                Text(layout.displayName)
                    .font(.caption)
                    .foregroundColor(isSelected ? ComicTheme.primary : .gray)
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 2)
            )
        }
    }
}
