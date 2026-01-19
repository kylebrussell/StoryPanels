import SwiftUI

struct ComicExportView: View {
    let comic: ComicDraft

    var body: some View {
        HStack(spacing: 2) {
            ForEach(comic.panels) { panel in
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 300, height: 300)

                    if let image = panel.generatedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 300)
                            .clipped()
                    }

                    ForEach(panel.textElements.sorted(by: { $0.zIndex < $1.zIndex }), id: \.id) { element in
                        TextElementExportView(element: element)
                            .position(element.position)
                    }
                }
                .frame(width: 300, height: 300)
            }
        }
        .background(Color.black)
    }
}
