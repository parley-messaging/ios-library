import Alamofire
import UIKit

internal class MessageRemoteService {
    
    internal func find(_ id: Int, onSuccess: @escaping (_ message: Message)->(), onFailure: @escaping (_ error: Error)->()) {
        ParleyRemote.execute(HTTPMethod.get, "messages/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findAll(onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        ParleyRemote.execute(HTTPMethod.get, "messages", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findBefore(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        ParleyRemote.execute(HTTPMethod.get, "messages/before:\(id)", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func findAfter(_ id: Int, onSuccess: @escaping (_ messageCollection: MessageCollection)->(), onFailure: @escaping (_ error: Error)->()) {
        ParleyRemote.execute(HTTPMethod.get, "messages/after:\(id)", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    internal func store(_ message: Message, onSuccess: @escaping (_ message: Message)->(), onFailure: @escaping (_ error: Error)->()) {
        if let imageURL = message.imageURL, let imageData = message.imageData {
            ParleyRemote.execute(path: "messages", multipartFormData: { multipartFormData in
                if imageURL.pathExtension == "png" {
                    multipartFormData.append(imageData, withName: "image", fileName: imageURL.lastPathComponent, mimeType: "image/png")
                } else if imageURL.pathExtension == "gif" {
                    multipartFormData.append(imageData, withName: "image", fileName: imageURL.lastPathComponent, mimeType: "image/gif")
                } else {
                    multipartFormData.append(imageData, withName: "image", fileName: imageURL.lastPathComponent, mimeType: "image/jpg")
                }
            }, onSuccess: { (savedMessage: Message) in
                message.id = savedMessage.id
                message.imageData = nil
                
                onSuccess(message)
            }, onFailure: onFailure)
        } else {
            ParleyRemote.execute(HTTPMethod.post, "messages", parameters: message.toJSON(), onSuccess: { (savedMessage: Message) in
                message.id = savedMessage.id
                
                onSuccess(message)
            }, onFailure: onFailure)
        }
    }
    
    @discardableResult internal func findImage(_ id: Int, onSuccess: @escaping (_ message: UIImage)->(), onFailure: @escaping (_ error: Error)->()) -> DataRequest? {
        return ParleyRemote.execute(.get, "images/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }
}
