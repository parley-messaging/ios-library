import Foundation
import UIKit

final class MessageRemoteService {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }

    func find(_ id: Int, onSuccess: @escaping (_ message: Message) -> Void, onFailure: @escaping (_ error: Error) -> Void) {
        remote.execute(.get, path: "messages/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }

    func findAll(
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        remote.execute(.get, path: "messages", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }

    @discardableResult
    func findBefore(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) -> ParleyRequestCancelable {
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
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
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
        onSuccess: @escaping (_ message: Message) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        DispatchQueue.global().async { [weak self] in
            guard let self else { return }
            remote.execute(
                .post,
                path: "messages",
                body: message,
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
        completion: @escaping ((Result<MediaResponse, Error>) -> Void)
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

    func findMedia(_ id: String, result: @escaping (Result<ParleyImageNetworkModel, Error>) -> Void) {
        remote.execute(.get, path: "media/\(id)", result: result)
    }
}
