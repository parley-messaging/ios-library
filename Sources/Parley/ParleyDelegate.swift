import Foundation

@MainActor
public protocol ParleyDelegate: AnyObject {

    func didChangeState(_ state: Parley.State)
    func didChangePushEnabled(_ pushEnabled: Bool)

    func reachable(pushEnabled: Bool)
    func unreachable(isCachingEnabled: Bool)
}
