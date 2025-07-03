import Foundation

final class EventRemoteService: Sendable {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }

    func fire(_ name: UserTypingEvent) async throws {
        try await remote.execute(.post, path: "services/event/\(name.rawValue)")
    }
}
