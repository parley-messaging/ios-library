import Foundation
import UIKit

protocol MessageRepositoryProtocol: AnyObject {
    
    func find(
        _ id: Int,
        onSuccess: @escaping (_ message: Message) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    )
    func find(_ id: Int) async throws -> Message

    func findAll(
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    )
    func findAll() async throws -> MessageCollection

    func findBefore(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    )
    func findBefore(_ id: Int) async throws -> MessageCollection

    func findAfter(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    )
    func findAfter(_ id: Int) async throws -> MessageCollection
    
    func store(_ message: Message) async throws -> Message
}

final class MessageRepository: MessageRepositoryProtocol {

    private let messageRemoteService: MessageRemoteService

    init(messageRemoteService: MessageRemoteService) {
        self.messageRemoteService = messageRemoteService
    }

    func find(
        _ id: Int,
        onSuccess: @escaping (_ message: Message) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        messageRemoteService.find(id, onSuccess: onSuccess, onFailure: onFailure)
    }

    func findAll(
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        messageRemoteService.findAll(onSuccess: onSuccess, onFailure: onFailure)
    }

    func findBefore(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        messageRemoteService.findBefore(id, onSuccess: onSuccess, onFailure: onFailure)
    }

    func findAfter(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        messageRemoteService.findAfter(id, onSuccess: onSuccess, onFailure: onFailure)
    }
}

// MARK: Async Methods
extension MessageRepository {
    
    func find(_ id: Int) async throws -> Message {
        try await messageRemoteService.find(id)
    }

    func findAll() async throws -> MessageCollection {
        try await messageRemoteService.findAll()
    }

    func findBefore(_ id: Int) async throws -> MessageCollection {
        try await messageRemoteService.findBefore(id)
    }

    func findAfter(_ id: Int) async throws -> MessageCollection {
        try await messageRemoteService.findAfter(id)
    }
    
    func store(_ message: Message) async throws -> Message {
        try await messageRemoteService.store(message)
    }
}
