import Foundation

enum ImageProviderID: String, CaseIterable, Identifiable {
    case google
    case openai

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .google: return "Google (Nano Banana Pro)"
        case .openai: return "OpenAI"
        }
    }
}

enum ImageGenerationSize: String, CaseIterable, Identifiable {
    case oneK = "1K"
    case twoK = "2K"
    case fourK = "4K"

    var id: String { rawValue }
}

enum ImageAspectRatio: String, CaseIterable, Identifiable {
    case square = "1:1"
    case landscape = "16:9"
    case portrait = "9:16"

    var id: String { rawValue }
}

enum SettingsKeys {
    static let provider = "image_provider"
    static let googleModelName = "google_model_name"
    static let googleImageSize = "google_image_size"
    static let googleAspectRatio = "google_aspect_ratio"
    static let openAIModelName = "openai_model_name"
}

enum SettingsStore {
    static var selectedProvider: ImageProviderID {
        get {
            let rawValue = UserDefaults.standard.string(forKey: SettingsKeys.provider) ?? ImageProviderID.google.rawValue
            return ImageProviderID(rawValue: rawValue) ?? .google
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: SettingsKeys.provider)
        }
    }

    static var googleModelName: String {
        get { UserDefaults.standard.string(forKey: SettingsKeys.googleModelName) ?? "gemini-3-pro-image-preview" }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKeys.googleModelName) }
    }

    static var googleImageSize: ImageGenerationSize {
        get {
            let rawValue = UserDefaults.standard.string(forKey: SettingsKeys.googleImageSize) ?? ImageGenerationSize.oneK.rawValue
            return ImageGenerationSize(rawValue: rawValue) ?? .oneK
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: SettingsKeys.googleImageSize) }
    }

    static var googleAspectRatio: ImageAspectRatio {
        get {
            let rawValue = UserDefaults.standard.string(forKey: SettingsKeys.googleAspectRatio) ?? ImageAspectRatio.square.rawValue
            return ImageAspectRatio(rawValue: rawValue) ?? .square
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: SettingsKeys.googleAspectRatio) }
    }

    static var openAIModelName: String {
        get { UserDefaults.standard.string(forKey: SettingsKeys.openAIModelName) ?? "gpt-image-1" }
        set { UserDefaults.standard.set(newValue, forKey: SettingsKeys.openAIModelName) }
    }
}
