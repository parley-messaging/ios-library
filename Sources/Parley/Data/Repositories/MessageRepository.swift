import Foundation
import UIKit

final class MessageRepository {
    
    private let remote: ParleyRemote
    private let messageRemoteService: MessageRemoteService
    
    init(remote: ParleyRemote) {
        self.remote = remote
        self.messageRemoteService = MessageRemoteService(remote: remote)
    }
    
    func find(_ id: Int, onSuccess: @escaping (_ message: Message) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        messageRemoteService.find(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func findAll(onSuccess: @escaping (_ messageCollection: MessageCollection) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        messageRemoteService.findAll(onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func findBefore(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        messageRemoteService.findBefore(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func findAfter(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        messageRemoteService.findAfter(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func store(_ message: Message, onSuccess: @escaping (_ message: Message) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        messageRemoteService.store(message, onSuccess: onSuccess, onFailure: onFailure)
    }
}
