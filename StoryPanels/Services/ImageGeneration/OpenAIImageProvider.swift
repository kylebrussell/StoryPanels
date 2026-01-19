import Foundation
import UIKit

struct OpenAIImageProvider: ImageGenerationProvider {
    let id: ImageProviderID = .openai
    let displayName: String = "OpenAI"

    private let apiKey: String
    private let modelName: String
    private let baseURL = "https://api.openai.com/v1"

    init(apiKey: String, modelName: String) {
        self.apiKey = apiKey
        self.modelName = modelName
    }

    func generate(request: ImageGenerationRequest) async throws -> UIImage {
        if let referenceImage = request.referenceImage {
            return try await generateWithEdit(prompt: request.prompt, referenceImage: referenceImage)
        }
        return try await generateFromText(prompt: request.prompt)
    }

    private func generateFromText(prompt: String) async throws -> UIImage {
        let url = URL(string: "\(baseURL)/images/generations")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let requestBody: [String: Any] = [
            "model": modelName,
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageGenerationError.invalidResponse
            }
            guard httpResponse.statusCode == 200 else {
                let message = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
                throw ImageGenerationError.providerError(message)
            }
            guard let imageData = try await parseImageData(from: data),
                  let image = UIImage(data: imageData) else {
                throw ImageGenerationError.noImageData
            }
            return image
        } catch let error as ImageGenerationError {
            throw error
        } catch {
            throw ImageGenerationError.network(error)
        }
    }

    private func generateWithEdit(prompt: String, referenceImage: UIImage) async throws -> UIImage {
        let url = URL(string: "\(baseURL)/images/edits")!
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        guard let imageData = referenceImage.pngData() else {
            throw ImageGenerationError.noImageData
        }

        var formData = Data()
        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        formData.append(modelName.data(using: .utf8)!)
        formData.append("\r\n".data(using: .utf8)!)

        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"image\"; filename=\"canvas.png\"\r\n".data(using: .utf8)!)
        formData.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        formData.append(imageData)
        formData.append("\r\n".data(using: .utf8)!)

        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
        formData.append(prompt.data(using: .utf8)!)
        formData.append("\r\n".data(using: .utf8)!)

        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"n\"\r\n\r\n".data(using: .utf8)!)
        formData.append("1".data(using: .utf8)!)
        formData.append("\r\n".data(using: .utf8)!)

        formData.append("--\(boundary)\r\n".data(using: .utf8)!)
        formData.append("Content-Disposition: form-data; name=\"size\"\r\n\r\n".data(using: .utf8)!)
        formData.append("1024x1024".data(using: .utf8)!)
        formData.append("\r\n".data(using: .utf8)!)

        formData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = formData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw ImageGenerationError.invalidResponse
            }
            guard httpResponse.statusCode == 200 else {
                let message = parseErrorMessage(from: data) ?? "HTTP \(httpResponse.statusCode)"
                throw ImageGenerationError.providerError(message)
            }
            guard let imageData = try await parseImageData(from: data),
                  let image = UIImage(data: imageData) else {
                throw ImageGenerationError.noImageData
            }
            return image
        } catch let error as ImageGenerationError {
            throw error
        } catch {
            throw ImageGenerationError.network(error)
        }
    }

    private func parseErrorMessage(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let error = json["error"] as? [String: Any],
              let message = error["message"] as? String else {
            return nil
        }
        return message
    }

    private func parseImageData(from data: Data) async throws -> Data? {
        guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = jsonResponse["data"] as? [[String: Any]],
              let firstImage = dataArray.first else {
            throw ImageGenerationError.invalidResponse
        }

        if let imageURLString = firstImage["url"] as? String,
           let imageURL = URL(string: imageURLString) {
            let (downloadedData, _) = try await URLSession.shared.data(from: imageURL)
            return downloadedData
        }

        if let base64String = firstImage["b64_json"] as? String,
           let decoded = Data(base64Encoded: base64String) {
            return decoded
        }

        return nil
    }
}
