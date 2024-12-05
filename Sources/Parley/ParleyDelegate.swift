import Foundation

protocol ParleyDelegate: AnyObject {

    func didChangeState(_ state: Parley.State)
    func didChangePushEnabled(_ pushEnabled: Bool)

    func reachable()
    func unreachable()
}
