import Foundation

protocol ParleyDelegate: AnyObject, Sendable {

    @MainActor func didChangeState(_ state: ParleyActor.State) async
    @MainActor func didChangePushEnabled(_ pushEnabled: Bool)

    @MainActor func reachable() async
    @MainActor func unreachable() async
}
