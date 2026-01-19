import Foundation
import SwiftData

@Model
final class ComicDocument {
    @Attribute(.unique) var id: UUID
    var layoutRaw: String
    var themeName: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade) var panels: [ComicPanelDocument]

    init(
        id: UUID = UUID(),
        layoutRaw: String,
        themeName: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        panels: [ComicPanelDocument] = []
    ) {
        self.id = id
        self.layoutRaw = layoutRaw
        self.themeName = themeName
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.panels = panels
    }
}

@Model
final class ComicPanelDocument {
    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    var imagePrompt: String
    var imageFilename: String?
    var lastGeneratedAt: Date?
    @Relationship(deleteRule: .cascade) var textElements: [TextElementDocument]
    @Relationship(deleteRule: .cascade) var characterStandIns: [CharacterStandInDocument]

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        imagePrompt: String = "",
        imageFilename: String? = nil,
        lastGeneratedAt: Date? = nil,
        textElements: [TextElementDocument] = [],
        characterStandIns: [CharacterStandInDocument] = []
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.imagePrompt = imagePrompt
        self.imageFilename = imageFilename
        self.lastGeneratedAt = lastGeneratedAt
        self.textElements = textElements
        self.characterStandIns = characterStandIns
    }
}

@Model
final class TextElementDocument {
    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    var typeRaw: String
    var text: String
    var positionX: Double
    var positionY: Double
    var width: Double
    var height: Double

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        typeRaw: String,
        text: String = "",
        positionX: Double,
        positionY: Double,
        width: Double,
        height: Double
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.typeRaw = typeRaw
        self.text = text
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
    }
}

@Model
final class CharacterStandInDocument {
    @Attribute(.unique) var id: UUID
    var orderIndex: Int
    var number: Int
    var label: String
    var positionX: Double
    var positionY: Double
    var width: Double
    var height: Double

    init(
        id: UUID = UUID(),
        orderIndex: Int,
        number: Int,
        label: String = "",
        positionX: Double,
        positionY: Double,
        width: Double,
        height: Double
    ) {
        self.id = id
        self.orderIndex = orderIndex
        self.number = number
        self.label = label
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
    }
}

extension ComicDocument: Identifiable {}
