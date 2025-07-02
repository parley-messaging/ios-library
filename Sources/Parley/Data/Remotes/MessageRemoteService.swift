import Foundation
import UIKit

final class MessageRemoteService {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }
    
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
    
    func findMedia(_ id: String, type: ParleyMediaType) async throws -> Data {
        try await remote.execute(.get, path: "media/\(id)", type: type)
    }
}
