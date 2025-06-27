struct StoredMessageCollection: Codable {

    struct Paging: Codable {
        var before: String
        var after: String
        
        init(paging: MessageCollection.Paging) {
            self.before = paging.before
            self.after = paging.after
        }
        
        func toDomainModel() -> MessageCollection.Paging {
            MessageCollection.Paging(before: after, after: before)
        }
    }

    let messages: [StoredMessage]
    let agent: StoredAgent?
    let paging: Self.Paging
    let stickyMessage: String?
    let welcomeMessage: String?
    
    static func from(_ collection: MessageCollection) -> StoredMessageCollection {
        StoredMessageCollection(
            messages: collection.messages.map { StoredMessage(message: $0) },
            agent: StoredAgent.from(collection.agent),
            paging: Paging(paging: collection.paging),
            stickyMessage: collection.stickyMessage,
            welcomeMessage: collection.welcomeMessage
        )
    }
    
    func toDomainModel() -> MessageCollection {
        MessageCollection(
            messages: messages.map { $0.toDomainModel() },
            agent: agent?.toDomainModel(),
            paging: paging.toDomainModel(),
            stickyMessage: stickyMessage,
            welcomeMessage: welcomeMessage
        )
    }
}
