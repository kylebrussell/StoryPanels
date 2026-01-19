import SwiftUI
import SwiftData

struct ComicEditorView: View {
    @StateObject private var viewModel: ComicEditorViewModel
    @State private var mostRecentTextElementIndex: Int?
    @State private var mostRecentCharacterIndex: Int?
    @FocusState private var isPromptFieldFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(layout: PanelLayout, modelContext: ModelContext, existingDocument: ComicDocument? = nil) {
        _viewModel = StateObject(
            wrappedValue: ComicEditorViewModel(
                layout: layout,
                modelContext: modelContext,
                existingDocument: existingDocument
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    VStack(spacing: 0) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 20) {
                                if viewModel.comic.layout == .single {
                                    Spacer()
                                }
                                ForEach(Array(viewModel.comic.panels.enumerated()), id: \.element.id) { index, panel in
                                    PanelView(
                                        panel: $viewModel.comic.panels[index],
                                        isSelected: viewModel.selectedPanelIndex == index,
                                        onTextElementInteraction: { elementIndex in
                                            if viewModel.selectedPanelIndex == index {
                                                mostRecentTextElementIndex = elementIndex
                                                mostRecentCharacterIndex = nil
                                            }
                                        },
                                        onCharacterInteraction: { characterIndex in
                                            if viewModel.selectedPanelIndex == index {
                                                mostRecentCharacterIndex = characterIndex
                                                mostRecentTextElementIndex = nil
                                            }
                                        },
                                        onInteractionFinished: {
                                            viewModel.scheduleAutosave()
                                        }
                                    )
                                    .id("panel_\(index)")
                                    .onTapGesture {
                                        viewModel.selectedPanelIndex = index
                                        mostRecentTextElementIndex = nil
                                        mostRecentCharacterIndex = nil
                                    }
                                }
                                if viewModel.comic.layout == .single {
                                    Spacer()
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity)
                        .background(ComicTheme.background)

                        VStack(spacing: 16) {
                            if viewModel.comic.layout == .threePanel {
                                HStack {
                                    ForEach(0..<3) { index in
                                        Button(action: {
                                            viewModel.selectedPanelIndex = index
                                            withAnimation(.easeInOut(duration: 0.5)) {
                                                proxy.scrollTo("panel_\(index)", anchor: .center)
                                            }
                                            mostRecentTextElementIndex = nil
                                            mostRecentCharacterIndex = nil
                                        }) {
                                            Text("Panel \(index + 1)")
                                                .font(.caption)
                                        }
                                        .buttonStyle(
                                            ComicButtonStyle(
                                                backgroundColor: viewModel.selectedPanelIndex == index ? ComicTheme.primary : ComicTheme.secondary.opacity(0.5),
                                                foregroundColor: .black,
                                                strokeColor: .black
                                            )
                                        )
                                    }
                                }
                            }

                            VStack(spacing: 8) {
                                Text("Art Style")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(StyleTheme.allThemes) { theme in
                                            Button(action: {
                                                viewModel.comic.selectedTheme = theme
                                                viewModel.scheduleAutosave()
                                            }) {
                                                Text(theme.name)
                                                    .font(.caption2)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 6)
                                                    .background(viewModel.comic.selectedTheme.name == theme.name ? ComicTheme.primary : ComicTheme.secondary.opacity(0.4))
                                                    .foregroundColor(.black)
                                                    .cornerRadius(6)
                                            }
                                        }
                                    }
                                }
                            }

                            VStack(spacing: 12) {
                                Text("Describe the image for Panel \(viewModel.selectedPanelIndex + 1)")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                HStack {
                                    TextField(
                                        "A superhero flying...",
                                        text: $viewModel.comic.panels[viewModel.selectedPanelIndex].imagePrompt
                                    )
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .focused($isPromptFieldFocused)

                                    Button(action: {
                                        viewModel.generateImage(for: viewModel.selectedPanelIndex)
                                    }) {
                                        if viewModel.comic.panels[viewModel.selectedPanelIndex].isGenerating {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle())
                                                .scaleEffect(0.8)
                                        } else {
                                            Text("Generate")
                                                .font(.caption)
                                                .frame(maxWidth: .infinity)
                                        }
                                    }
                                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.primary, foregroundColor: .white))
                                    .disabled(viewModel.comic.panels[viewModel.selectedPanelIndex].isGenerating || viewModel.comic.panels[viewModel.selectedPanelIndex].imagePrompt.isEmpty)
                                }

                                HStack {
                                    Button("Try Again") {
                                        viewModel.retryGeneration(for: viewModel.selectedPanelIndex)
                                    }
                                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.secondary, foregroundColor: .black))
                                    .disabled(viewModel.comic.panels[viewModel.selectedPanelIndex].imagePrompt.isEmpty)

                                    if viewModel.comic.panels[viewModel.selectedPanelIndex].isGenerating {
                                        Button("Cancel") {
                                            viewModel.cancelGeneration(for: viewModel.selectedPanelIndex)
                                        }
                                        .buttonStyle(ComicButtonStyle(backgroundColor: .red, foregroundColor: .white))
                                    }
                                }
                            }

                            VStack(spacing: 8) {
                                Text("Add Characters")
                                    .font(.caption)
                                    .foregroundColor(.gray)

                                HStack(spacing: 12) {
                                    Button(action: {
                                        viewModel.addCharacterStandIn(to: viewModel.selectedPanelIndex)
                                        mostRecentCharacterIndex = viewModel.comic.panels[viewModel.selectedPanelIndex].characterStandIns.count - 1
                                        mostRecentTextElementIndex = nil
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: "person.circle.fill")
                                                .font(.system(size: 20))
                                            Text("Character")
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(ComicButtonStyle(backgroundColor: Color.blue.opacity(0.7), foregroundColor: .white))
                                }
                            }

                            HStack(spacing: 12) {
                                ForEach(TextElementType.allCases, id: \.self) { type in
                                    Button(action: {
                                        viewModel.addTextElement(type: type, to: viewModel.selectedPanelIndex)
                                        mostRecentTextElementIndex = viewModel.comic.panels[viewModel.selectedPanelIndex].textElements.count - 1
                                        mostRecentCharacterIndex = nil
                                    }) {
                                        VStack(spacing: 4) {
                                            Image(systemName: type.icon)
                                                .font(.system(size: 20))
                                            Text(type.rawValue)
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                    .buttonStyle(ComicButtonStyle(backgroundColor: ComicTheme.secondary, foregroundColor: .black))
                                }
                            }

                            if let mostRecentIndex = mostRecentTextElementIndex,
                               mostRecentIndex < viewModel.comic.panels[viewModel.selectedPanelIndex].textElements.count {
                                Button(action: {
                                    viewModel.comic.panels[viewModel.selectedPanelIndex].textElements.remove(at: mostRecentIndex)
                                    mostRecentTextElementIndex = nil
                                    viewModel.scheduleAutosave()
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Remove Text")
                                    }
                                }
                                .buttonStyle(ComicButtonStyle(backgroundColor: .red, foregroundColor: .white))
                            } else if let mostRecentIndex = mostRecentCharacterIndex,
                                      mostRecentIndex < viewModel.comic.panels[viewModel.selectedPanelIndex].characterStandIns.count {
                                Button(action: {
                                    viewModel.comic.panels[viewModel.selectedPanelIndex].characterStandIns.remove(at: mostRecentIndex)
                                    mostRecentCharacterIndex = nil
                                    viewModel.scheduleAutosave()
                                }) {
                                    HStack {
                                        Image(systemName: "trash.fill")
                                        Text("Remove Character")
                                    }
                                }
                                .buttonStyle(ComicButtonStyle(backgroundColor: .red, foregroundColor: .white))
                            }
                        }
                        .padding()
                        .background(ComicTheme.background)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(y: isPromptFieldFocused ? -40 : 0)
            .animation(.easeInOut(duration: 0.25), value: isPromptFieldFocused)
            .background(ComicTheme.background)
            .navigationTitle("Comic Editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        viewModel.saveDraft()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        viewModel.exportComic()
                    }
                    .disabled(viewModel.comic.panels.allSatisfy { $0.generatedImage == nil })
                }
            }
            .sheet(isPresented: $viewModel.isShowingExportSheet) {
                if let image = viewModel.exportedImage {
                    ExportView(
                        image: image,
                        bakedImage: viewModel.bakedImage,
                        onBake: {
                            await viewModel.bakeExportedComic()
                        },
                        onSave: { savedImage in
                            viewModel.saveToPhotos(image: savedImage)
                        }
                    )
                }
            }
            .alert("Save Result", isPresented: $viewModel.showSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.saveAlertMessage)
            }
            .alert("Generation Error", isPresented: Binding<Bool>(
                get: { viewModel.generationErrorMessage != nil },
                set: { _ in viewModel.generationErrorMessage = nil }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.generationErrorMessage ?? "")
            }
            .background(ComicTheme.background)
            .ignoresSafeArea()
            .toolbarBackground(ComicTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onDisappear {
                viewModel.saveDraft()
            }
        }
    }
}
