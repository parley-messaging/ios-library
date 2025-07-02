import Foundation
import UIKit

protocol MessageRepositoryProtocol: AnyObject {
    
    func find(_ id: Int) async throws -> Message

    func findAll() async throws -> MessageCollection

    func findBefore(_ id: Int) async throws -> MessageCollection

    func findAfter(_ id: Int) async throws -> MessageCollection
    
    func store(_ message: Message) async throws -> Message
}

final class MessageRepository: MessageRepositoryProtocol {

    private let messageRemoteService: MessageRemoteService

    init(messageRemoteService: MessageRemoteService) {
        self.messageRemoteService = messageRemoteService
    }
    
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
