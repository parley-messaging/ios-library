public protocol ParleyMessageDataSource: AnyObject, ParleyDataSource, Sendable {

    func all() async -> [Message]?

    func save(_ messages: [Message]) async

    func insert(_ message: Message, at index: Int) async

    func update(_ message: Message) async
}
