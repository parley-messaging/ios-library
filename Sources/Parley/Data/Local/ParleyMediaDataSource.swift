import Foundation

@available(*, deprecated, renamed: "ParleyMediaDataSource", message: "Use ParleyMediaDataSource instead")
public typealias ParleyImageDataSource = ParleyMediaDataSource

public protocol ParleyMediaDataSource: AnyObject, ParleyDataSource {

    func all() -> [ParleyStoredMedia]

    func media(id: ParleyStoredMedia.ID) -> ParleyStoredMedia?

    func save(media: [ParleyStoredMedia])

    func save(media: ParleyStoredMedia)

    @discardableResult
    func delete(id: ParleyStoredMedia.ID) -> Bool
}
