import Foundation
import SwiftUI
import SwiftData
import Photos

@MainActor
final class ComicEditorViewModel: ObservableObject {
    @Published var comic: ComicDraft
    @Published var selectedPanelIndex: Int = 0
    @Published var exportedImage: UIImage?
    @Published var bakedImage: UIImage?
    @Published var isShowingExportSheet: Bool = false
    @Published var showSaveAlert: Bool = false
    @Published var saveAlertMessage: String = ""
    @Published var generationErrorMessage: String?

    private let modelContext: ModelContext
    private var document: ComicDocument?
    private var generationTasks: [UUID: Task<Void, Never>] = [:]
    private var autosaveTask: Task<Void, Never>?

    init(layout: PanelLayout, modelContext: ModelContext, existingDocument: ComicDocument? = nil) {
        self.modelContext = modelContext
        if let existingDocument {
            self.document = existingDocument
            self.comic = ComicDocumentMapper.draft(from: existingDocument)
        } else {
            self.document = nil
            self.comic = ComicDraft(layout: layout)
        }
    }

    func generateImage(for panelIndex: Int) {
        guard panelIndex >= 0, panelIndex < comic.panels.count else { return }
        let panelId = comic.panels[panelIndex].id

        generationTasks[panelId]?.cancel()
        generationTasks[panelId] = nil
        comic.panels[panelIndex].isGenerating = true
        comic.panels[panelIndex].lastErrorMessage = nil

        let panel = comic.panels[panelIndex]
        let shouldUseReference = !panel.characterStandIns.isEmpty || !panel.textElements.isEmpty
        let prompt = shouldUseReference
            ? PromptBuilder.layoutEditPrompt(basePrompt: panel.imagePrompt, theme: comic.selectedTheme)
            : PromptBuilder.generationPrompt(basePrompt: panel.imagePrompt, theme: comic.selectedTheme)

        let referenceImage = shouldUseReference ? captureCanvasSnapshot(for: panelIndex) : nil

        let task = Task { [weak self] in
            guard let self else { return }
            do {
                let image = try await ImageGenerationService.shared.generateImage(
                    prompt: prompt,
                    referenceImage: referenceImage
                )
                await MainActor.run {
                    self.comic.panels[panelIndex].generatedImage = image
                    self.comic.panels[panelIndex].lastGeneratedAt = Date()
                    self.comic.panels[panelIndex].isGenerating = false
                    self.scheduleAutosave()
                    self.generationTasks[panelId] = nil
                }
            } catch let error as ImageGenerationError {
                await MainActor.run {
                    let message: String
                    switch error {
                    case .missingAPIKey:
                        message = "Missing API key. Add it in Settings."
                    case .providerError(let details):
                        message = "Generation failed: \(details)"
                    case .network:
                        message = "Network error. Check your connection and try again."
                    case .invalidResponse, .noImageData:
                        message = "Generation failed. Try again."
                    }
                    self.handleGenerationError(message: message)
                    self.comic.panels[panelIndex].isGenerating = false
                    self.generationTasks[panelId] = nil
                }
            } catch {
                await MainActor.run {
                    self.handleGenerationError(message: "Image generation failed. Try again.")
                    self.comic.panels[panelIndex].isGenerating = false
                    self.generationTasks[panelId] = nil
                }
            }
        }

        generationTasks[panelId] = task
    }

    func cancelGeneration(for panelIndex: Int) {
        guard panelIndex >= 0, panelIndex < comic.panels.count else { return }
        let panelId = comic.panels[panelIndex].id
        generationTasks[panelId]?.cancel()
        generationTasks[panelId] = nil
        comic.panels[panelIndex].isGenerating = false
    }

    func retryGeneration(for panelIndex: Int) {
        generateImage(for: panelIndex)
    }

    func addCharacterStandIn(to panelIndex: Int) {
        guard panelIndex >= 0, panelIndex < comic.panels.count else { return }
        let nextNumber = comic.panels[panelIndex].characterStandIns.count + 1
        var character = CharacterStandIn(number: nextNumber)
        character.position = CGPoint(x: 100 + CGFloat(comic.panels[panelIndex].characterStandIns.count * 90), y: 200)
        comic.panels[panelIndex].characterStandIns.append(character)
        scheduleAutosave()
    }

    func addTextElement(type: TextElementType, to panelIndex: Int) {
        guard panelIndex >= 0, panelIndex < comic.panels.count else { return }
        var element = TextElement(type: type)
        switch type {
        case .speechBubble:
            element.size = CGSize(width: 120, height: 60)
        case .thoughtBubble:
            element.size = CGSize(width: 100, height: 80)
        case .caption:
            element.size = CGSize(width: 140, height: 40)
        case .soundEffect:
            element.size = CGSize(width: 100, height: 100)
        }
        element.position = CGPoint(x: 150, y: 100 + CGFloat(comic.panels[panelIndex].textElements.count * 80))
        element.zIndex = comic.panels[panelIndex].textElements.count
        comic.panels[panelIndex].textElements.append(element)
        scheduleAutosave()
    }

    func exportComic() {
        let renderer = ImageRenderer(content: ComicExportView(comic: comic))
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            exportedImage = image
            bakedImage = nil
            isShowingExportSheet = true
        }
    }

    func bakeExportedComic() async {
        let renderer = ImageRenderer(content: ComicExportView(comic: comic))
        renderer.scale = UIScreen.main.scale
        guard let rendered = renderer.uiImage else { return }
        let prompt = PromptBuilder.bakeTextPrompt(basePrompt: aggregatePrompt(), theme: comic.selectedTheme)
        do {
            let baked = try await ImageGenerationService.shared.generateImage(prompt: prompt, referenceImage: rendered)
            await MainActor.run {
                bakedImage = baked
            }
        } catch {
            await MainActor.run {
                handleGenerationError(message: "Bake failed. Try again.")
            }
        }
    }

    func saveToPhotos(image: UIImage) {
        Task {
            let status = await requestPhotoPermissionIfNeeded()
            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    saveAlertMessage = "Photos permission denied. Enable it in Settings."
                    showSaveAlert = true
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.saveAlertMessage = "Comic saved to your Photos!"
                    } else {
                        self.saveAlertMessage = "Failed to save image."
                    }
                    self.showSaveAlert = true
                }
            }
        }
    }

    func saveDraft() {
        comic.updatedAt = Date()
        let updatedDocument = ComicDocumentMapper.update(document: document, with: comic)
        if document == nil {
            modelContext.insert(updatedDocument)
            document = updatedDocument
        } else {
            document = updatedDocument
        }
        do {
            try modelContext.save()
        } catch {
            print("Failed to save comic: \(error.localizedDescription)")
        }
    }

    func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                self?.saveDraft()
            }
        }
    }

    private func handleGenerationError(message: String) {
        generationErrorMessage = message
    }

    private func captureCanvasSnapshot(for panelIndex: Int) -> UIImage? {
        let panel = comic.panels[panelIndex]
        let renderer = ImageRenderer(content: CanvasSnapshotView(panel: panel))
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func aggregatePrompt() -> String {
        let prompts = comic.panels.enumerated().map { index, panel in
            let trimmed = panel.imagePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            let content = trimmed.isEmpty ? "Panel \(index + 1)" : "Panel \(index + 1): \(trimmed)"
            return content
        }
        return prompts.joined(separator: ". ")
    }

    private func requestPhotoPermissionIfNeeded() async -> PHAuthorizationStatus {
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        if currentStatus == .notDetermined {
            return await withCheckedContinuation { continuation in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    continuation.resume(returning: status)
                }
            }
        }
        return currentStatus
    }
}
