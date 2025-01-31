import Foundation
import UIKit

final class MessageRemoteService {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }

    func find(
        _ id: Int,
        onSuccess: @escaping (_ message: Message) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        remote.execute(.get, path: "messages/\(id)", onSuccess: onSuccess, onFailure: onFailure)
    }

    func findAll(
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        remote.execute(.get, path: "messages", keyPath: nil, onSuccess: onSuccess, onFailure: onFailure)
    }

    func findBefore(
        _ id: Int,
        onSuccess: @escaping (_ messageCollection: MessageCollection) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
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
        data: Data,
        type: ParleyMediaType,
        fileName: String,
        completion: @escaping ((Result<MediaResponse, Error>) -> Void)
    ) {
        remote.execute(
            path: "media",
            data: data,
            name: "media",
            fileName: fileName,
            type: type,
            result: completion
        )
    }

    func findMedia(_ id: String, type: ParleyMediaType, result: @escaping (Result<Data, Error>) -> Void) {
        remote.execute(.get, path: "media/\(id)", type: type, result: result)
    }
}

// MARK: Async Methods
extension MessageRemoteService {
    
    func find(_ id: Int) async throws -> Message {
        try await remote.execute(.get, path: "messages/\(id)")
    }
    
    func findAll() async throws -> MessageCollection {
        try await remote.execute(.get, path: "messages", keyPath: nil)
    }
    
    func findBefore(_ id: Int) async throws -> MessageCollection {
        try await remote.execute(.get, path: "messages/before:\(id)", keyPath: nil)
    }
    
    func findAfter(_ id: Int) async throws -> MessageCollection {
        try await remote.execute(.get, path: "messages/after:\(id)", keyPath: nil)
    }
    
    func store(_ message: Message) async throws -> Message {
        try await remote.execute(.post, path: "messages", body: message)
    }
    
    func upload(data: Data, type: ParleyMediaType, fileName: String) async -> Result<MediaResponse, Error> {
        do {
            let mediaResponse: MediaResponse = try await remote.execute(
                path: "media",
                data: data,
                name: "media",
                fileName: fileName,
                type: type
            )
            return .success(mediaResponse)
        } catch {
            return .failure(error)
        }
    }
}
