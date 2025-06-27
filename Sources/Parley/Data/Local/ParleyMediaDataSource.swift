import Foundation

@available(*, deprecated, renamed: "ParleyMediaDataSource", message: "Use ParleyMediaDataSource instead")
public typealias ParleyImageDataSource = ParleyMediaDataSource

public protocol ParleyMediaDataSource: AnyObject, ParleyDataSource, Sendable {

    func all() async -> [ParleyStoredMedia]

    func media(id: ParleyStoredMedia.ID) async -> ParleyStoredMedia?

    func save(media: [ParleyStoredMedia]) async

    func save(media: ParleyStoredMedia) async

    @discardableResult
    func delete(id: ParleyStoredMedia.ID) async -> Bool
}
