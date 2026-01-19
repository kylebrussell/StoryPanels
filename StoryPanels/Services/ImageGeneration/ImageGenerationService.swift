import Foundation
import UIKit

final class ImageGenerationService {
    static let shared = ImageGenerationService()

    private let keychain = KeychainStore()

    func generateImage(prompt: String, referenceImage: UIImage?) async throws -> UIImage {
        let provider = try makeProvider()
        let request = ImageGenerationRequest(
            prompt: prompt,
            size: SettingsStore.googleImageSize,
            aspectRatio: SettingsStore.googleAspectRatio,
            referenceImage: referenceImage
        )
        return try await provider.generate(request: request)
    }

    private func makeProvider() throws -> ImageGenerationProvider {
        switch SettingsStore.selectedProvider {
        case .google:
            let apiKey = keychain.get(KeychainKeys.googleAPIKey)
            guard let apiKey, !apiKey.isEmpty else {
                throw ImageGenerationError.missingAPIKey
            }
            return GoogleGeminiImageProvider(
                apiKey: apiKey,
                modelName: SettingsStore.googleModelName,
                imageSize: SettingsStore.googleImageSize,
                aspectRatio: SettingsStore.googleAspectRatio
            )
        case .openai:
            let apiKey = keychain.get(KeychainKeys.openAIAPIKey)
            guard let apiKey, !apiKey.isEmpty else {
                throw ImageGenerationError.missingAPIKey
            }
            return OpenAIImageProvider(
                apiKey: apiKey,
                modelName: SettingsStore.openAIModelName
            )
        }
    }
}
