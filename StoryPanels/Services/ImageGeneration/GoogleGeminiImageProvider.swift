import Foundation
import UIKit

struct GoogleGeminiImageProvider: ImageGenerationProvider {
    let id: ImageProviderID = .google
    let displayName: String = "Google Nano Banana Pro"

    private let apiKey: String
    private let modelName: String
    private let imageSize: ImageGenerationSize
    private let aspectRatio: ImageAspectRatio

    init(apiKey: String, modelName: String, imageSize: ImageGenerationSize, aspectRatio: ImageAspectRatio) {
        self.apiKey = apiKey
        self.modelName = modelName
        self.imageSize = imageSize
        self.aspectRatio = aspectRatio
    }

    func generate(request: ImageGenerationRequest) async throws -> UIImage {
        let endpoint = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent"
        guard let url = URL(string: endpoint) else {
            throw ImageGenerationError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bundleId = Bundle.main.bundleIdentifier {
            urlRequest.setValue(bundleId, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        urlRequest.timeoutInterval = 60

        let contentParts = buildParts(prompt: request.prompt, referenceImage: request.referenceImage)
        let body = GeminiGenerateRequest(
            contents: [
                GeminiGenerateRequest.Content(parts: contentParts)
            ],
            generationConfig: GeminiGenerateRequest.GenerationConfig(
                responseModalities: ["IMAGE"],
                imageConfig: GeminiGenerateRequest.ImageConfig(
                    aspectRatio: aspectRatio.rawValue,
                    imageSize: imageSize.rawValue
                )
            )
        )

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(body)

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageGenerationError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                let message = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
                throw ImageGenerationError.providerError(message)
            }

            guard let image = try parseImage(from: data) else {
                throw ImageGenerationError.noImageData
            }

            return image
        } catch let error as ImageGenerationError {
            throw error
        } catch {
            throw ImageGenerationError.network(error)
        }
    }

    private func buildParts(prompt: String, referenceImage: UIImage?) -> [GeminiGenerateRequest.Part] {
        var parts: [GeminiGenerateRequest.Part] = [
            GeminiGenerateRequest.Part(text: prompt, inlineData: nil)
        ]
        if let referenceImage, let imageData = referenceImage.pngData() {
            let base64 = imageData.base64EncodedString()
            let inlineData = GeminiGenerateRequest.InlineData(mimeType: "image/png", data: base64)
            parts.append(GeminiGenerateRequest.Part(text: nil, inlineData: inlineData))
        }
        return parts
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }

    private func parseImage(from data: Data) throws -> UIImage? {
        let response = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
        let imageData = response.candidates
            .compactMap { $0.content }
            .flatMap { $0.parts }
            .compactMap { $0.inlineData?.data }
            .compactMap { Data(base64Encoded: $0) }
            .first

        guard let imageData else { return nil }
        return UIImage(data: imageData)
    }
}

struct GeminiGenerateRequest: Encodable {
    struct Content: Encodable {
        let parts: [Part]
    }

    struct Part: Encodable {
        let text: String?
        let inlineData: InlineData?

        enum CodingKeys: String, CodingKey {
            case text
            case inlineData = "inline_data"
        }
    }

    struct InlineData: Encodable {
        let mimeType: String
        let data: String

        enum CodingKeys: String, CodingKey {
            case mimeType = "mime_type"
            case data
        }
    }

    struct GenerationConfig: Encodable {
        let responseModalities: [String]
        let imageConfig: ImageConfig

        enum CodingKeys: String, CodingKey {
            case responseModalities
            case imageConfig
        }
    }

    struct ImageConfig: Encodable {
        let aspectRatio: String
        let imageSize: String
    }

    let contents: [Content]
    let generationConfig: GenerationConfig
}

struct GeminiGenerateResponse: Decodable {
    struct Candidate: Decodable {
        let content: Content?
    }

    struct Content: Decodable {
        let parts: [Part]
    }

    struct Part: Decodable {
        let inlineData: InlineData?
        let text: String?

        enum CodingKeys: String, CodingKey {
            case inlineData = "inlineData"
            case inline_data
            case text
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            inlineData = try container.decodeIfPresent(InlineData.self, forKey: .inlineData)
                ?? container.decodeIfPresent(InlineData.self, forKey: .inline_data)
            text = try container.decodeIfPresent(String.self, forKey: .text)
        }
    }

    struct InlineData: Decodable {
        let mimeType: String?
        let data: String?

        enum CodingKeys: String, CodingKey {
            case mimeType = "mimeType"
            case mime_type
            case data
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
                ?? container.decodeIfPresent(String.self, forKey: .mime_type)
            data = try container.decodeIfPresent(String.self, forKey: .data)
        }
    }

    let candidates: [Candidate]
}
