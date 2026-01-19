import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ComicDocument.updatedAt, order: .reverse) private var comics: [ComicDocument]
    @State private var showingEditor = false
    @State private var selectedLayout: PanelLayout = .single
    @State private var showingSettings = false
    @State private var selectedComic: ComicDocument?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    Image("AppTitle")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 200)

                    Image("LaunchLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .padding(.top, -40)

                    VStack(spacing: 20) {
                        Text("Select Layout")
                            .font(.headline)

                        HStack(spacing: 20) {
                            ForEach(PanelLayout.allCases, id: \.self) { layout in
                                LayoutButton(
                                    layout: layout,
                                    isSelected: selectedLayout == layout
                                ) {
                                    selectedLayout = layout
                                }
                            }
                        }

                        Button(action: {
                            showingEditor = true
                        }) {
                            Label("Create Comic", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(ComicButtonStyle(variant: .primary))
                    }
                    .padding(.horizontal)

                    if comics.isEmpty {
                        Text("No saved comics yet. Start your first one!")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 12)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Comics")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 12) {
                                ForEach(comics, id: \.id) { comic in
                                    Button {
                                        selectedComic = comic
                                    } label: {
                                        ComicCardView(
                                            comic: comic,
                                            thumbnail: loadThumbnail(for: comic)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ComicTheme.paperBackground)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                ComicEditorView(
                    layout: selectedLayout,
                    modelContext: modelContext
                )
            }
            .sheet(item: $selectedComic) { comic in
                ComicEditorView(
                    layout: PanelLayout(rawValue: comic.layoutRaw) ?? .single,
                    modelContext: modelContext,
                    existingDocument: comic
                )
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private func loadThumbnail(for comic: ComicDocument) -> UIImage? {
        let panel = comic.panels.sorted(by: { $0.orderIndex < $1.orderIndex }).first
        guard let filename = panel?.imageFilename else { return nil }
        return ImageStore.shared.loadThumbnail(named: filename, maxDimension: 72)
    }
}
