import Foundation

final class EventRemoteService {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }

    func fire(_ name: UserTypingEvent, onSuccess: @escaping () -> Void, onFailure: @escaping (_ error: Error) -> Void) {
        remote.execute(.post, path: "services/event/\(name.rawValue)", onSuccess: onSuccess, onFailure: onFailure)
    }
}

// MARK: Async Methods
extension EventRemoteService {
    
    func fire(_ name: UserTypingEvent) async throws {
        try await remote.execute(.post, path: "services/event/\(name.rawValue)")
    }
}
