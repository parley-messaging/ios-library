import Foundation
import UIKit

final class MessageRemoteService: MessageRepository, Sendable {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }
    
    func find(_ id: Int) async throws -> Message {
        let message: MessageResponse = try await remote.execute(.get, path: "messages/\(id)")
        return message.toDomainModel(id: UUID())
    }
    
    func findAll() async throws -> MessageCollection {
        let collection: MessageCollectionResponse = try await remote.execute(.get, path: "messages", keyPath: nil)
        return collection.toDomainModel()
    }
    
    func findBefore(_ id: Int) async throws -> MessageCollection {
        let collection: MessageCollectionResponse = try await remote.execute(.get, path: "messages/before:\(id)", keyPath: nil)
        return collection.toDomainModel()
    }
    
    func findAfter(_ id: Int) async throws -> MessageCollection {
        let collection: MessageCollectionResponse = try await remote.execute(.get, path: "messages/after:\(id)", keyPath: nil)
        return collection.toDomainModel()
    }
    
    func store(_ message: inout Message) async throws {
        let request = NewMessageRequest(message: message)
        let storedMessage: MessageResponse = try await remote.execute(
            .post,
            path: "messages",
            body: request
        )
        message.remoteId = storedMessage.remoteId
    }
    
    func upload(data: Data, type: ParleyMediaType, fileName: String) async -> Result<MediaResponse, Error> {
        do {
            let mediaResponse: MediaResponse = try await remote.execute(
                path: "media",
                data: data,
                name: "media",
                fileName: fileName,
                type: type
            )
            return .success(mediaResponse)
        } catch {
            return .failure(error)
        }
    }
    
    func findMedia(_ id: String, type: ParleyMediaType) async throws -> Data {
        try await remote.execute(.get, path: "media/\(id)", type: type)
    }
}
