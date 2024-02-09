import Foundation
import UIKit

final class MessageRemoteService {

    private let remote: ParleyRemote
    private let codableHelper: CodableHelper

    init(remote: ParleyRemote, codableHelper: CodableHelper = .shared) {
        self.remote = remote
        self.codableHelper = codableHelper
    }

    func find(_ id: Int, onSuccess: @escaping (_ message: Message) -> (), onFailure: @escaping (_ error: Error) -> ()) {
        remote.execute(.get, path: "messages/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }

    func findAll(
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        remote.execute(.get, path: "messages", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }

    func findBefore(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        remote.execute(
            .get,
            path: "messages/before:\(id)",
            keyPath: nil,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }

    func findAfter(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        remote.execute(
            .get,
            path: "messages/after:\(id)",
            keyPath: nil,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }

    func store(
        _ message: Message,
        onSuccess: @escaping (_ message: Message) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        DispatchQueue.global().async { [weak self] in
            if let imageURL = message.imageURL, let imageData = message.imageData, message.media == nil { // Deprecated
                self?.remote.execute(path: "messages", multipartFormData: { multipartFormData in
                    let type = ParleyImageType.map(from: imageURL)
                    multipartFormData.add(
                        key: "image",
                        fileName: imageURL.lastPathComponent,
                        fileMimeType: type.mimeType,
                        fileData: imageData
                    )
                }, onSuccess: { (savedMessage: Message) in
                    message.id = savedMessage.id
                    message.imageData = nil

                    onSuccess(message)
                }, onFailure: onFailure)
            } else {
                self?.remote.execute(
                    .post,
                    path: "messages",
                    parameters: try? self?.codableHelper.toDictionary(message),
                    onSuccess: { (savedMessage: Message) in
                        message.id = savedMessage.id
                        onSuccess(message)
                    },
                    onFailure: onFailure
                )
            }
        }
    }

    func upload(
        imageData: Data,
        imageType: ParleyImageType,
        fileName: String,
        completion: @escaping ((Result<MediaResponse, Error>) -> ())
    ) {
        remote.execute(
            path: "media",
            imageData: imageData,
            name: "media",
            fileName: fileName,
            imageType: imageType,
            result: completion
        )
    }

    @available(*, deprecated)
    @discardableResult
    func findImage(
        _ id: Int,
        onSuccess: @escaping (_ message: UIImage) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) -> RequestCancelable? {
        remote.execute(.get, path: "images/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }

    @discardableResult
    func findMedia(
        _ id: String,
        onSuccess: @escaping (_ message: UIImage) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) -> RequestCancelable? {
        remote.execute(.get, path: "media/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }
}
