import UIKit
import UniformTypeIdentifiers

extension NSItemProvider {
    
    enum NSItemProviderLoadImageError: Error {
        case unexpectedImageType
        case unableToConvertToUIImage
        case failedToLoadDataRepresentation
    }
    
    @available(iOS 14.0, *)
    struct LoadedImage {
        let image: UIImage
        let data: Data
        let type: UTType
    }
    
    @available(iOS 14.0, *)
    func loadImage() async throws -> LoadedImage {
        if canLoadObject(ofClass: UIImage.self) {
            let image = try await loadUIImage()
            guard let typeIdentifier = image.cgImage?.utType as? String, let type = UTType(typeIdentifier) else {
                throw NSItemProviderLoadImageError.unexpectedImageType
            }
            let data = try await loadDataRepresentation(forTypeIdentifier: typeIdentifier)
            return LoadedImage(image: image, data: data, type: type)
        } else if hasItemConformingToTypeIdentifier(UTType.webP.identifier) {
            let (image, data) = try await loadImageWithDataRepresentation(forTypeIdentifier: UTType.webP.identifier)
            return LoadedImage(image: image, data: data, type: .webP)
        } else {
            throw NSItemProviderLoadImageError.unexpectedImageType
        }
    }
    
    private func loadUIImage() async throws -> UIImage {
        return try await withCheckedThrowingContinuation { continuation in
            loadObject(ofClass: UIImage.self) { image, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let resultImage = image as? UIImage {
                    continuation.resume(returning: resultImage)
                } else {
                    continuation.resume(throwing: NSItemProviderLoadImageError.unableToConvertToUIImage)
                }
            }
        }
    }
    
    private func loadImageWithDataRepresentation(forTypeIdentifier identifier: String) async throws -> (UIImage, Data) {
        let data = try await loadDataRepresentation(forTypeIdentifier: identifier)
        if let image = UIImage(data: data) {
            return (image, data)
        } else {
            throw NSItemProviderLoadImageError.unableToConvertToUIImage
        }
    }
    
    private func loadDataRepresentation(forTypeIdentifier identifier: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            loadDataRepresentation(forTypeIdentifier: identifier) { data, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: NSItemProviderLoadImageError.failedToLoadDataRepresentation)
                }
            }
        }
    }
}
