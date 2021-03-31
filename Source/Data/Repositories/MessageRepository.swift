import Alamofire
import UIKit

internal class MessageRepository {
    
    private let messageRemoteService = MessageRemoteService()
    
    internal func find(_ id: Int, onSuccess: @escaping (_ message: Message)->(), onFailure: @escaping (_ error: Error)->()) {
        self.messageRemoteService.find(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findAll(onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        self.messageRemoteService.findAll(onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findBefore(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        self.messageRemoteService.findBefore(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findAfter(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        self.messageRemoteService.findAfter(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func store(_ message: Message, onSuccess: @escaping (_ message: Message)->(), onFailure: @escaping (_ error: Error)->()) {
        self.messageRemoteService.store(message, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult internal func findImage(_ messageId: Int, onSuccess: @escaping (_ message: UIImage)->(), onFailure: @escaping (_ error: Error)->()) -> DataRequest? {
        return self.messageRemoteService.findImage(messageId, onSuccess: onSuccess, onFailure: onFailure)
    }
}
