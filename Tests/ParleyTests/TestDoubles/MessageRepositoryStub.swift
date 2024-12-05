@testable import Parley

final class MessageRepositoryStub: MessageRepositoryProtocol {
    
    private var find = [Int: Result<Message, Error>]()
    private var findAll: Result<MessageCollection, Error>!
    private var findBefore = [Int: Result<MessageCollection, Error>]()
    private var findAfter = [Int: Result<MessageCollection, Error>]()
    private var store: Result<Message, Error>!
    
    func find(_ id: Int, onSuccess: @escaping (Message) -> Void, onFailure: @escaping (Error) -> Void) {
        switch find[id]! {
        case .success(let message):
            onSuccess(message)
        case .failure(let error):
            onFailure(error)
        }
    }

    func findAll(onSuccess: @escaping (MessageCollection) -> Void, onFailure: @escaping (Error) -> Void) {
        switch findAll! {
        case .success(let collection):
            onSuccess(collection)
        case .failure(let error):
            onFailure(error)
        }
    }

    func findBefore(
        _ id: Int,
        onSuccess: @escaping (MessageCollection) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        switch findBefore[id]! {
        case .success(let collection):
            onSuccess(collection)
        case .failure(let error):
            onFailure(error)
        }
    }

    func findAfter(
        _ id: Int,
        onSuccess: @escaping (MessageCollection) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        switch findAfter[id]! {
        case .success(let collection):
            onSuccess(collection)
        case .failure(let error):
            onFailure(error)
        }
    }

    func store(_ message: Message) async throws -> Message {
        try store.get()
    }
}

extension MessageRepositoryStub {
    
    func whenFind(id: Int, _ result: Result<Message, Error>) {
        find[id] = result
    }
    
    func whenFindAll(_ result: Result<MessageCollection, Error>) {
        findAll = result
    }

    func whenFindBefore(id: Int, _ result: Result<MessageCollection, Error>) {
        findBefore[id] = result
    }
    
    func whenFindAfter(id: Int, _ result: Result<MessageCollection, Error>) {
        findAfter[id] = result
    }
    
    func whenStore(_ result: Result<Message, Error>) {
        store = result
    }
}
