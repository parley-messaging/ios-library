public protocol ParleyMessageDataSource: AnyObject {

    func all() -> [Message]?

    func save(_ messages: [Message])

    func insert(_ message: Message, at index: Int)

    func update(_ message: Message)
}
