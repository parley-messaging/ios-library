import Foundation

public protocol ParleyImageDataSource: AnyObject, ParleyDataSource {

    func all() -> [ParleyStoredMedia]

    func image(id: ParleyStoredMedia.ID) -> ParleyStoredMedia?

    func save(images: [ParleyStoredMedia])

    func save(image: ParleyStoredMedia)

    @discardableResult
    func delete(id: ParleyStoredMedia.ID) -> Bool
}
