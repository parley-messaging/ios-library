import Foundation

final class EventRemoteService {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }

    func fire(_ name: UserTypingEvent, onSuccess: @escaping () -> (), onFailure: @escaping (_ error: Error) -> ()) {
        remote.execute(.post, path: "services/event/\(name.rawValue)", onSuccess: onSuccess, onFailure: onFailure)
    }
}
