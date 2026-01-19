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

    private var themeSelection: Binding<String> {
        Binding(
            get: { viewModel.comic.selectedTheme.name },
            set: { newValue in
                viewModel.comic.selectedTheme = StyleTheme.theme(named: newValue)
                viewModel.scheduleAutosave()
            }
        )
    }

    private var panelSection: some View {
        sectionCard(title: "Panels") {
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
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private var panelPickerSection: some View {
        if viewModel.comic.layout == .threePanel {
            sectionCard(title: "Panel") {
                Picker("Panel", selection: $viewModel.selectedPanelIndex) {
                    ForEach(0..<3) { index in
                        Text("Panel \(index + 1)").tag(index)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var styleSection: some View {
        sectionCard(title: "Art Style") {
            Picker("Art Style", selection: themeSelection) {
                ForEach(StyleTheme.allThemes) { theme in
                    Text(theme.name).tag(theme.name)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var promptSection: some View {
        let panel = viewModel.comic.panels[viewModel.selectedPanelIndex]
        return sectionCard(title: "Describe the image for Panel \(viewModel.selectedPanelIndex + 1)") {
            HStack(spacing: 12) {
                TextField(
                    "A superhero flying...",
                    text: $viewModel.comic.panels[viewModel.selectedPanelIndex].imagePrompt
                )
                .textFieldStyle(.roundedBorder)
                .focused($isPromptFieldFocused)

                Button(action: {
                    viewModel.generateImage(for: viewModel.selectedPanelIndex)
                }) {
                    HStack(spacing: 6) {
                        if panel.isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .scaleEffect(0.8)
                        }
                        Text(panel.isGenerating ? "Generating" : "Generate")
                    }
                }
                .buttonStyle(ComicButtonStyle(variant: .primary, isCompact: true))
                .disabled(panel.isGenerating || panel.imagePrompt.isEmpty)
            }

            HStack(spacing: 12) {
                Button("Try Again") {
                    viewModel.retryGeneration(for: viewModel.selectedPanelIndex)
                }
                .buttonStyle(ComicButtonStyle(variant: .secondary, isCompact: true))
                .disabled(panel.imagePrompt.isEmpty)

                if panel.isGenerating {
                    Button(role: .destructive) {
                        viewModel.cancelGeneration(for: viewModel.selectedPanelIndex)
                    } label: {
                        Text("Cancel")
                    }
                    .buttonStyle(ComicButtonStyle(variant: .destructive, isCompact: true))
                }
            }
        }
    }

    private var characterSection: some View {
        sectionCard(title: "Characters") {
            Button(action: {
                viewModel.addCharacterStandIn(to: viewModel.selectedPanelIndex)
                mostRecentCharacterIndex = viewModel.comic.panels[viewModel.selectedPanelIndex].characterStandIns.count - 1
                mostRecentTextElementIndex = nil
            }) {
                Label("Add Character", systemImage: "person.crop.circle.badge.plus")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(ComicButtonStyle(variant: .secondary))
        }
    }

    private var textElementsSection: some View {
        sectionCard(title: "Text Elements") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(TextElementType.allCases, id: \.self) { type in
                    Button(action: {
                        viewModel.addTextElement(type: type, to: viewModel.selectedPanelIndex)
                        mostRecentTextElementIndex = viewModel.comic.panels[viewModel.selectedPanelIndex].textElements.count - 1
                        mostRecentCharacterIndex = nil
                    }) {
                        Label(type.rawValue, systemImage: type.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(ComicButtonStyle(variant: .secondary, isCompact: true))
                }
            }
        }
    }

    @ViewBuilder
    private var removalSection: some View {
        if let mostRecentIndex = mostRecentTextElementIndex,
           mostRecentIndex < viewModel.comic.panels[viewModel.selectedPanelIndex].textElements.count {
            Button(role: .destructive) {
                viewModel.comic.panels[viewModel.selectedPanelIndex].textElements.remove(at: mostRecentIndex)
                mostRecentTextElementIndex = nil
                viewModel.scheduleAutosave()
            } label: {
                Label("Remove Text", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ComicButtonStyle(variant: .destructive))
        } else if let mostRecentIndex = mostRecentCharacterIndex,
                  mostRecentIndex < viewModel.comic.panels[viewModel.selectedPanelIndex].characterStandIns.count {
            Button(role: .destructive) {
                viewModel.comic.panels[viewModel.selectedPanelIndex].characterStandIns.remove(at: mostRecentIndex)
                mostRecentCharacterIndex = nil
                viewModel.scheduleAutosave()
            } label: {
                Label("Remove Character", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ComicButtonStyle(variant: .destructive))
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            content()
        }
        .padding()
        .background(ComicTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: ComicTheme.Metrics.largeCornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: ComicTheme.Metrics.largeCornerRadius, style: .continuous)
                .stroke(ComicTheme.outline, lineWidth: ComicTheme.Metrics.outlineWidth)
        )
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: ComicTheme.Metrics.sectionSpacing) {
                        panelSection
                        panelPickerSection
                        styleSection
                        promptSection
                        characterSection
                        textElementsSection
                        removalSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                }
                .onChange(of: viewModel.selectedPanelIndex) { newValue in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        proxy.scrollTo("panel_\(newValue)", anchor: .center)
                    }
                    mostRecentTextElementIndex = nil
                    mostRecentCharacterIndex = nil
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .background(ComicTheme.paperBackground)
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
            .background(ComicTheme.paperBackground.ignoresSafeArea())
            .onDisappear {
                viewModel.saveDraft()
            }
        }
    }
}
