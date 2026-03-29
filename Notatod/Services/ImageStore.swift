import AppKit
import Foundation

actor ImageStore {
    private let baseURL: URL
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        let supportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        baseURL = supportURL.appendingPathComponent("Notatod/images", isDirectory: true)
        try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    func imageURL(for filename: String) -> URL {
        baseURL.appendingPathComponent(filename)
    }

    func save(image: NSImage) throws -> String {
        let filename = "\(UUID().uuidString).jpg"
        let destination = imageURL(for: filename)
        let normalizedImage = resize(image: image, maxDimension: 1600)

        guard let tiff = normalizedImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) else {
            throw CocoaError(.fileWriteUnknown)
        }

        try data.write(to: destination)
        return filename
    }

    func delete(filename: String) throws {
        let url = imageURL(for: filename)
        guard fileManager.fileExists(atPath: url.path) else { return }
        try fileManager.removeItem(at: url)
    }

    private func resize(image: NSImage, maxDimension: CGFloat) -> NSImage {
        guard max(image.size.width, image.size.height) > maxDimension else {
            return image
        }

        let scale = maxDimension / max(image.size.width, image.size.height)
        let newSize = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let newImage = NSImage(size: newSize)

        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize), from: NSRect(origin: .zero, size: image.size), operation: .copy, fraction: 1)
        newImage.unlockFocus()

        return newImage
    }
}
