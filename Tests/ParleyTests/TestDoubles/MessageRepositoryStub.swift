@testable import Parley

final actor MessageRepositoryStub: MessageRepository {

    private var find = [Int: Result<Message, Error>]()
    private var findAll: Result<MessageCollection, Error>!
    private var findBefore = [Int: Result<MessageCollection, Error>]()
    private var findAfter = [Int: Result<MessageCollection, Error>]()
    private var store: Result<Message, Error>!
    private var unseen: Result<Int, Error>!
    private var updateStatusRead: Result<Void, Error>!
    
    func find(_ id: Int) async throws -> Message {
        return try find[id]!.get()
    }

    func findAll() async throws -> MessageCollection {
        try findAll!.get()
    }

    func findBefore(_ id: Int) async throws -> MessageCollection {
        try findBefore[id]!.get()
    }

    func findAfter(_ id: Int) async throws -> MessageCollection {
        try findAfter[id]!.get()
    }

    func store(_ message: inout Message) async throws {
        message = try store.get()
    }
    
    func getUnseen() async throws -> Int {
        try unseen.get()
    }
    
    func updateStatusRead(messageIds: Set<Int>) async throws {
        try updateStatusRead.get()
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
    
    func whenUnseenCount(_ result: Result<Int, Error>) {
        unseen = result
    }
    
    func whenUpdateRead(_ result: Result<Void, Error>) {
        updateStatusRead = result
    }
}
