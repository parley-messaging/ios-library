import Alamofire
import UIKit

internal class MessageRepository {
    
    private let messageRemoteService = MessageRemoteService()
    
    internal func find(_ id: Int, onSuccess: @escaping (_ message: Message)->(), onFailure: @escaping (_ error: Error)->()) {
        messageRemoteService.find(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findAll(onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        messageRemoteService.findAll(onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findBefore(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        messageRemoteService.findBefore(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findAfter(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        messageRemoteService.findAfter(id, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func store(_ message: Message, onSuccess: @escaping (_ message: Message)->(), onFailure: @escaping (_ error: Error)->()) {
        messageRemoteService.store(message, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func upload(imageData: Data, imageType: ImageType, fileName: String, completion: @escaping ((Result<MediaResponse, Error>) -> ())) {
        messageRemoteService.upload(imageData: imageData, imageType: imageType, fileName: fileName, completion: completion)
    }
    
    @available(*, deprecated)
    @discardableResult internal func findImage(_ messageId: Int, onSuccess: @escaping (_ message: UIImage)->(), onFailure: @escaping (_ error: Error)->()) -> DataRequest? {
        messageRemoteService.findImage(messageId, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult internal func findMedia(_ messageId: Int, onSuccess: @escaping (_ message: UIImage) -> (), onFailure: @escaping (_ error: Error) -> ()) -> DataRequest? {
        messageRemoteService.findMedia(messageId, onSuccess: onSuccess, onFailure: onFailure)
    }
}
