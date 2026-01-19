import Foundation
import UIKit

struct ImageGenerationRequest {
    let prompt: String
    let size: ImageGenerationSize
    let aspectRatio: ImageAspectRatio
    let referenceImage: UIImage?
}

enum ImageGenerationError: Error {
    case missingAPIKey
    case invalidResponse
    case noImageData
    case providerError(String)
    case network(Error)
}

protocol ImageGenerationProvider {
    var id: ImageProviderID { get }
    var displayName: String { get }

    func generate(request: ImageGenerationRequest) async throws -> UIImage
}
