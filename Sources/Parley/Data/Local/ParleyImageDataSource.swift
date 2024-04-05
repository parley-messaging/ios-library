import Foundation

public protocol ParleyImageDataSource: AnyObject, ParleyDataSource {

    func all() -> [ParleyStoredImage]

    func image(id: ParleyStoredImage.ID) -> ParleyStoredImage?

    func save(images: [ParleyStoredImage])

    func save(image: ParleyStoredImage)

    @discardableResult
    func delete(id: ParleyStoredImage.ID) -> Bool
}
