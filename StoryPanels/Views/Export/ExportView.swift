import SwiftUI

struct ExportView: View {
    let image: UIImage
    let bakedImage: UIImage?
    let onBake: () async -> Void
    let onSave: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var useBaked: Bool = false
    @State private var isBaking: Bool = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(uiImage: currentImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()

                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            isBaking = true
                            await onBake()
                            isBaking = false
                            if bakedImage != nil {
                                useBaked = true
                            }
                        }
                    }) {
                        if isBaking {
                            Label("Baking Text...", systemImage: "sparkles")
                        } else {
                            Label("Bake Text into Art", systemImage: "sparkles")
                        }
                    }
                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.secondary, foregroundColor: .black))
                    .disabled(isBaking)

                    if bakedImage != nil {
                        Toggle("Use baked version", isOn: $useBaked)
                            .toggleStyle(SwitchToggleStyle(tint: ComicTheme.primary))
                    }
                }
                .padding(.horizontal)

                HStack(spacing: 20) {
                    Button(action: {
                        onSave(currentImage)
                    }) {
                        Label("Save to Photos", systemImage: "square.and.arrow.down")
                    }
                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.primary, foregroundColor: .white))
                    .frame(maxWidth: .infinity)

                    ShareLink(item: Image(uiImage: currentImage), preview: SharePreview("My Comic", image: Image(uiImage: currentImage))) {
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Export Comic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .background(ComicTheme.background)
        .ignoresSafeArea()
        .toolbarBackground(ComicTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onChange(of: bakedImage) { newValue in
            if newValue != nil {
                useBaked = true
            }
        }
    }

    private var currentImage: UIImage {
        if useBaked, let bakedImage {
            return bakedImage
        }
        return image
    }
}
