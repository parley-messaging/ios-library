import Foundation

protocol ParleyDelegate: AnyObject {

    func didChangeState(_ state: Parley.State)
    func didChangePushEnabled(_ pushEnabled: Bool)

    func didReceiveMessage(_ indexPaths: [IndexPath])
    func didReceiveMessages()
    func didLoadMore()

    func didStartTyping()
    func didStopTyping()

    func willSend(_ indexPaths: [IndexPath])
    func didUpdate(_ message: Message)
    func didSent(_ message: Message)

    func reachable()
    func unreachable()
}
