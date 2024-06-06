@testable import Parley

final class MessageRepositoryStub: MessageRepositoryProtocol {
    func find(_ id: Int, onSuccess: @escaping (Message) -> Void, onFailure: @escaping (Error) -> Void) {
        onSuccess(Message.makeTestData())
    }

    func findAll(onSuccess: @escaping (MessageCollection) -> Void, onFailure: @escaping (Error) -> Void) {
    }

    func findBefore(
        _ id: Int,
        onSuccess: @escaping (MessageCollection) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {

    }

    func findAfter(
        _ id: Int,
        onSuccess: @escaping (MessageCollection) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {

    }

    func store(_ message: Message) async throws -> Message {
        message
    }
}
