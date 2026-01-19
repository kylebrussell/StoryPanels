import SwiftUI

enum PanelLayout: String, CaseIterable, Codable {
    case single
    case threePanel

    var panelCount: Int {
        switch self {
        case .single: return 1
        case .threePanel: return 3
        }
    }

    var displayName: String {
        switch self {
        case .single: return "1 Panel"
        case .threePanel: return "3 Panels"
        }
    }
}

enum TextElementType: String, CaseIterable, Codable {
    case speechBubble = "Speech"
    case thoughtBubble = "Thought"
    case caption = "Caption"
    case soundEffect = "Sound"

    var icon: String {
        switch self {
        case .speechBubble: return "bubble.left.fill"
        case .thoughtBubble: return "cloud.fill"
        case .caption: return "rectangle.fill"
        case .soundEffect: return "star.fill"
        }
    }
}

struct CharacterStandIn: Identifiable {
    let id: UUID
    var number: Int
    var position: CGPoint
    var size: CGSize
    var label: String

    init(
        id: UUID = UUID(),
        number: Int,
        position: CGPoint = CGPoint(x: 100, y: 200),
        size: CGSize = CGSize(width: 80, height: 80),
        label: String = ""
    ) {
        self.id = id
        self.number = number
        self.position = position
        self.size = size
        self.label = label
    }
}

struct TextElement: Identifiable {
    let id: UUID
    var type: TextElementType
    var text: String
    var position: CGPoint
    var size: CGSize
    var isEditing: Bool
    var zIndex: Int

    init(
        id: UUID = UUID(),
        type: TextElementType,
        text: String = "",
        position: CGPoint = CGPoint(x: 150, y: 100),
        size: CGSize = CGSize(width: 120, height: 60),
        isEditing: Bool = false,
        zIndex: Int = 0
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.position = position
        self.size = size
        self.isEditing = isEditing
        self.zIndex = zIndex
    }
}

struct ComicPanelState: Identifiable {
    let id: UUID
    var imagePrompt: String
    var generatedImage: UIImage?
    var imageFilename: String?
    var textElements: [TextElement]
    var characterStandIns: [CharacterStandIn]
    var isGenerating: Bool
    var lastGeneratedAt: Date?
    var lastErrorMessage: String?

    init(
        id: UUID = UUID(),
        imagePrompt: String = "",
        generatedImage: UIImage? = nil,
        imageFilename: String? = nil,
        textElements: [TextElement] = [],
        characterStandIns: [CharacterStandIn] = [],
        isGenerating: Bool = false,
        lastGeneratedAt: Date? = nil,
        lastErrorMessage: String? = nil
    ) {
        self.id = id
        self.imagePrompt = imagePrompt
        self.generatedImage = generatedImage
        self.imageFilename = imageFilename
        self.textElements = textElements
        self.characterStandIns = characterStandIns
        self.isGenerating = isGenerating
        self.lastGeneratedAt = lastGeneratedAt
        self.lastErrorMessage = lastErrorMessage
    }
}

struct ComicDraft: Identifiable {
    let id: UUID
    var layout: PanelLayout
    var panels: [ComicPanelState]
    var selectedTheme: StyleTheme
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        layout: PanelLayout,
        selectedTheme: StyleTheme = StyleTheme.defaultTheme,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.layout = layout
        self.panels = (0..<layout.panelCount).map { _ in ComicPanelState() }
        self.selectedTheme = selectedTheme
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
