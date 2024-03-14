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
    ) -> RequestCancelable {
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
    
    internal func findMedia(_ id: String, result: @escaping (Result<ParleyImageNetworkModel, Error>) -> Void) {
        remote.execute(.get, path: "media/\(id)", result: result)
    }
}
