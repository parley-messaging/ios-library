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
    
    func getUnseen() async throws -> Int {
        try checkSupportsMessageStatus()
        let response: UnseenMessagesResponse = try await remote.execute(
            .get,
            path: "messages/unseen/count"
        )
        return response.toDomainModel().count
    }
    
    func updateStatusRead(messageIds: Set<Int>) async throws {
        try checkSupportsMessageStatus()
        let request = UpdateMessageStatusRequest(messageIds: messageIds)
        let status = MessageResponse.Status.read.key
        return try await remote.execute(.put, path: "messages/status/\(status)", body: request)
    }
    
    private func checkSupportsMessageStatus() throws(ParleyActor.ConfigurationError) {
        guard remote.apiVersion.isSupportingMessageStatus else {
            throw ParleyActor.ConfigurationError(
                code: -1,
                message: "ClientApi \(remote.apiVersion) does not support retrieving the unseen count."
            )
        }
    }
}
