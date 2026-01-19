import Foundation
import SwiftUI

enum ComicDocumentMapper {
    static func draft(from document: ComicDocument, imageStore: ImageStore = .shared) -> ComicDraft {
        let layout = PanelLayout(rawValue: document.layoutRaw) ?? .single
        let theme = StyleTheme.theme(named: document.themeName)
        var draft = ComicDraft(
            id: document.id,
            layout: layout,
            selectedTheme: theme,
            createdAt: document.createdAt,
            updatedAt: document.updatedAt
        )

        let sortedPanels = document.panels.sorted(by: { $0.orderIndex < $1.orderIndex })
        draft.panels = sortedPanels.map { panelDoc in
            let generatedImage = panelDoc.imageFilename.flatMap { imageStore.loadImage(named: $0) }
            let textElements = panelDoc.textElements
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .map { elementDoc in
                    TextElement(
                        id: elementDoc.id,
                        type: TextElementType(rawValue: elementDoc.typeRaw) ?? .speechBubble,
                        text: elementDoc.text,
                        position: CGPoint(x: elementDoc.positionX, y: elementDoc.positionY),
                        size: CGSize(width: elementDoc.width, height: elementDoc.height),
                        isEditing: false,
                        zIndex: elementDoc.orderIndex
                    )
                }

            let characterStandIns = panelDoc.characterStandIns
                .sorted(by: { $0.orderIndex < $1.orderIndex })
                .map { characterDoc in
                    CharacterStandIn(
                        id: characterDoc.id,
                        number: characterDoc.number,
                        position: CGPoint(x: characterDoc.positionX, y: characterDoc.positionY),
                        size: CGSize(width: characterDoc.width, height: characterDoc.height),
                        label: characterDoc.label
                    )
                }

            return ComicPanelState(
                id: panelDoc.id,
                imagePrompt: panelDoc.imagePrompt,
                generatedImage: generatedImage,
                imageFilename: panelDoc.imageFilename,
                textElements: textElements,
                characterStandIns: characterStandIns,
                isGenerating: false,
                lastGeneratedAt: panelDoc.lastGeneratedAt,
                lastErrorMessage: nil
            )
        }

        return draft
    }

    static func update(document: ComicDocument?, with draft: ComicDraft, imageStore: ImageStore = .shared) -> ComicDocument {
        let documentToUpdate: ComicDocument
        if let document {
            documentToUpdate = document
        } else {
            documentToUpdate = ComicDocument(
                id: draft.id,
                layoutRaw: draft.layout.rawValue,
                themeName: draft.selectedTheme.name,
                createdAt: draft.createdAt,
                updatedAt: draft.updatedAt
            )
        }

        documentToUpdate.layoutRaw = draft.layout.rawValue
        documentToUpdate.themeName = draft.selectedTheme.name
        documentToUpdate.updatedAt = Date()

        documentToUpdate.panels = draft.panels.enumerated().map { index, panel in
            let panelDoc = panelDocument(from: panel, orderIndex: index, imageStore: imageStore)
            return panelDoc
        }

        return documentToUpdate
    }

    private static func panelDocument(from panel: ComicPanelState, orderIndex: Int, imageStore: ImageStore) -> ComicPanelDocument {
        let filename: String?
        if let image = panel.generatedImage {
            filename = (try? imageStore.saveImage(image, existingFilename: panel.imageFilename)) ?? panel.imageFilename
        } else {
            filename = panel.imageFilename
        }

        let textElements = panel.textElements.enumerated().map { index, element in
            TextElementDocument(
                id: element.id,
                orderIndex: index,
                typeRaw: element.type.rawValue,
                text: element.text,
                positionX: element.position.x,
                positionY: element.position.y,
                width: element.size.width,
                height: element.size.height
            )
        }

        let characterStandIns = panel.characterStandIns.enumerated().map { index, character in
            CharacterStandInDocument(
                id: character.id,
                orderIndex: index,
                number: character.number,
                label: character.label,
                positionX: character.position.x,
                positionY: character.position.y,
                width: character.size.width,
                height: character.size.height
            )
        }

        return ComicPanelDocument(
            id: panel.id,
            orderIndex: orderIndex,
            imagePrompt: panel.imagePrompt,
            imageFilename: filename,
            lastGeneratedAt: panel.lastGeneratedAt,
            textElements: textElements,
            characterStandIns: characterStandIns
        )
    }
}
