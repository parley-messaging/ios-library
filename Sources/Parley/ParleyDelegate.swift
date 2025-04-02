import Foundation

public protocol ParleyDelegate: AnyObject, Sendable {

    func didChangeState(_ state: Parley.State) async
    func didChangePushEnabled(_ pushEnabled: Bool) async

    func reachable() async
    func unreachable() async
}
