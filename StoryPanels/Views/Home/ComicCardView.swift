import SwiftUI

struct ComicCardView: View {
    let comic: ComicDocument
    let thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(ComicTheme.surface)
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(ComicTheme.outline, lineWidth: ComicTheme.Metrics.outlineWidth)
                    )
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 68, height: 68)
                        .clipped()
                        .cornerRadius(6)
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(comicTitle)
                    .font(.headline)
                Text(comicSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(ComicTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(ComicTheme.outline, lineWidth: ComicTheme.Metrics.outlineWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: ComicTheme.subtleShadow, radius: 2, x: 0, y: 1)
    }

    private var comicTitle: String {
        let layout = PanelLayout(rawValue: comic.layoutRaw) ?? .single
        return "\(layout.displayName) Comic"
    }

    private var comicSubtitle: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Updated \(formatter.string(from: comic.updatedAt))"
    }
}
