//
//  StoryPanelsTests.swift
//  StoryPanelsTests
//
//  Created by Kyle Russell on 5/22/25.
//

import Testing
import SwiftData
@testable import StoryPanels

struct StoryPanelsTests {

    @Test func comicInitializesPanels() {
        let comic = ComicDraft(layout: .threePanel)
        #expect(comic.panels.count == 3)
    }

    @Test func promptBuilderIncludesThemeModifier() {
        let theme = StyleTheme(name: "Test", promptModifier: "in test style")
        let prompt = PromptBuilder.generationPrompt(basePrompt: "A robot", theme: theme)
        #expect(prompt.contains("A robot"))
        #expect(prompt.contains("in test style"))
    }

    @Test func promptBuilderHandlesEmptyPrompt() {
        let theme = StyleTheme(name: "Test", promptModifier: "in test style")
        let prompt = PromptBuilder.generationPrompt(basePrompt: "   ", theme: theme)
        #expect(prompt.contains("Comic panel"))
    }

    @Test func geminiResponseDecodesInlineData() throws {
        let base64 = Data([0x89, 0x50, 0x4E, 0x47]).base64EncodedString()
        let json = """
        {
          "candidates": [
            {
              "content": {
                "parts": [
                  { "inlineData": { "mimeType": "image/png", "data": "\(base64)" } }
                ]
              }
            }
          ]
        }
        """
        let response = try JSONDecoder().decode(GeminiGenerateResponse.self, from: Data(json.utf8))
        let decoded = response.candidates.first?.content?.parts.first?.inlineData?.data
        #expect(decoded == base64)
    }

    @Test func comicPersistenceRoundTrip() throws {
        let schema = Schema([ComicDocument.self, ComicPanelDocument.self, TextElementDocument.self, CharacterStandInDocument.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)

        var draft = ComicDraft(layout: .single)
        draft.panels[0].imagePrompt = "A test prompt"
        draft.selectedTheme = StyleTheme.theme(named: "Classic")

        let document = ComicDocumentMapper.update(document: nil, with: draft)
        context.insert(document)
        try context.save()

        let results = try context.fetch(FetchDescriptor<ComicDocument>())
        #expect(results.count == 1)

        let restored = ComicDocumentMapper.draft(from: results[0])
        #expect(restored.panels.first?.imagePrompt == "A test prompt")
    }
}
