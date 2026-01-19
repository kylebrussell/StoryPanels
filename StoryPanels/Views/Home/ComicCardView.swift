import SwiftUI

struct ComicCardView: View {
    let comic: ComicDocument
    let thumbnail: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 72, height: 72)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 2)
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
                        .foregroundColor(.gray.opacity(0.6))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(comicTitle)
                    .font(.headline)
                Text(comicSubtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black, lineWidth: 2)
        )
        .cornerRadius(12)
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
