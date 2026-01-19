import Foundation
import UIKit

struct ImageStore {
    static let shared = ImageStore()
    private let fileManager = FileManager.default
    private let folderName = "ComicImages"

    func saveImage(_ image: UIImage, existingFilename: String? = nil) throws -> String {
        let filename = existingFilename ?? "\(UUID().uuidString).png"
        let url = try imageURL(for: filename)
        let data = image.pngData()
        try ensureFolderExists()
        try data?.write(to: url, options: [.atomic])
        return filename
    }

    func loadImage(named filename: String) -> UIImage? {
        let cacheKey = "full:\(filename)"
        if let cached = ImageCache.shared.image(forKey: cacheKey) {
            return cached
        }
        guard let url = try? imageURL(for: filename),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        ImageCache.shared.setImage(image, forKey: cacheKey)
        return image
    }

    func deleteImage(named filename: String) {
        guard let url = try? imageURL(for: filename) else { return }
        try? fileManager.removeItem(at: url)
    }

    func loadThumbnail(named filename: String, maxDimension: CGFloat) -> UIImage? {
        let cacheKey = "thumb:\(filename):\(Int(maxDimension))"
        if let cached = ImageCache.shared.image(forKey: cacheKey) {
            return cached
        }
        guard let image = loadImage(named: filename) else { return nil }
        let thumbnail = ImageUtilities.downsample(image: image, maxDimension: maxDimension)
        ImageCache.shared.setImage(thumbnail, forKey: cacheKey)
        return thumbnail
    }

    private func imageURL(for filename: String) throws -> URL {
        try ensureFolderExists()
        return try imagesFolderURL().appendingPathComponent(filename)
    }

    private func imagesFolderURL() throws -> URL {
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw NSError(domain: "ImageStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing documents directory"])
        }
        return directory.appendingPathComponent(folderName, isDirectory: true)
    }

    private func ensureFolderExists() throws {
        let folderURL = try imagesFolderURL()
        if !fileManager.fileExists(atPath: folderURL.path) {
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        }
    }
}
