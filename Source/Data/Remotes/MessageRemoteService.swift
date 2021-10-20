import Alamofire
import UIKit


internal class MessageRemoteService {
    
    internal func find(_ id: Int, onSuccess: @escaping (_ message: Message) -> (), onFailure: @escaping (_ error: Error)->()) {
        ParleyRemote.execute(HTTPMethod.get, "messages/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findAll(onSuccess: @escaping (_ messageCollection: MessageCollection) -> (), onFailure: @escaping (_ error: Error)->()) {
        ParleyRemote.execute(HTTPMethod.get, "messages", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findBefore(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        ParleyRemote.execute(HTTPMethod.get, "messages/before:\(id)", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findAfter(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        ParleyRemote.execute(HTTPMethod.get, "messages/after:\(id)", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func store(_ message: Message, onSuccess: @escaping (_ message: Message) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        DispatchQueue.global().async {
            if let imageURL = message.imageURL, let imageData = message.imageData { // Depricated
                ParleyRemote.execute(path: "messages", multipartFormData: { multipartFormData in
                    let type = ParleyImageType.map(from: imageURL)
                    multipartFormData.append(imageData, withName: "image", fileName: imageURL.lastPathComponent, mimeType: type.mimeType)
                }, onSuccess: { (savedMessage: Message) in
                    message.id = savedMessage.id
                    message.imageData = nil
                    
                    onSuccess(message)
                }, onFailure: onFailure)
            } else {
                ParleyRemote.execute(.post, "messages", parameters: message.toJSON(), onSuccess: { (savedMessage: Message) in
                    message.id = savedMessage.id
                    
                    onSuccess(message)
                }, onFailure: onFailure)
            }
        }
    }
    
    internal func upload(imageData: Data, imageType: ParleyImageType, fileName: String, completion: @escaping ((Result<MediaResponse, Error>) -> ())) {
        let multipartFormData = MultipartFormData()
        multipartFormData.append(imageData, withName: "media", fileName: fileName, mimeType: imageType.mimeType)
        ParleyRemote.execute(path: "media", multipartFormData: multipartFormData, result: completion)
    }
    
    @available(*, deprecated)
    @discardableResult internal func findImage(_ id: Int, onSuccess: @escaping (_ message: UIImage) -> (), onFailure: @escaping (_ error: Error) -> ()) -> DataRequest? {
        ParleyRemote.execute(.get, "images/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }
    
    @discardableResult internal func findMedia(_ id: String, onSuccess: @escaping (_ message: UIImage) -> (), onFailure: @escaping (_ error: Error) -> ()) -> DataRequest? {
        ParleyRemote.execute(.get, "media/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }
}
