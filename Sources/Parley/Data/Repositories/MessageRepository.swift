import Foundation
import UIKit

protocol MessageRepository: AnyObject, Sendable {
    
    func find(_ id: Message.RemoteId) async throws -> Message

    func findAll() async throws -> MessageCollection

    func findBefore(_ id: Message.RemoteId) async throws -> MessageCollection

    func findAfter(_ id: Message.RemoteId) async throws -> MessageCollection
    
    func store(_ message: inout Message) async throws
    
    func getUnseen() async throws -> Int
    
    func updateStatusRead(messageIds: Set<Int>) async throws
}
