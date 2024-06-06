import Foundation
import UIKit

protocol MessageRepositoryProtocol: AnyObject {
    func find(
        _ id: Int,
        onSuccess: @escaping (_ message: Message) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    )

    func findAll(
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    )

    func findBefore(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    )

    func findAfter(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    )

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

    func store(_ message: Message) async throws -> Message {
        try await withCheckedThrowingContinuation { continuation in
            messageRemoteService.store(message) { message in
                continuation.resume(returning: message)
            } onFailure: { error in
                continuation.resume(throwing: error)
            }
        }
    }
}
