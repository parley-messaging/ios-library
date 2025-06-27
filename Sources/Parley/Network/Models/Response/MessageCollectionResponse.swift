import Foundation

struct MessageCollectionResponse: Codable {

    struct Paging: Codable, Equatable {
        var before: String
        var after: String

        init(before: String, after: String) {
            self.before = before
            self.after = after
        }
        
        func toDomainModel() -> MessageCollection.Paging {
            MessageCollection.Paging(before: before, after: after)
        }
    }

    var messages: [MessageResponse] = []
    var agent: AgentResponse?
    var paging: Paging
    var stickyMessage: String?
    var welcomeMessage: String?

    enum CodingKeys: String, CodingKey {
        case messages = "data"
        case agent
        case paging
        case stickyMessage
        case welcomeMessage
    }
    
    func toDomainModel() -> MessageCollection {
        MessageCollection(
            messages: messages.map { $0.toDomainModel(id: UUID()) },
            agent: agent?.toDomainModel(),
            paging: paging.toDomainModel(),
            stickyMessage: stickyMessage,
            welcomeMessage: welcomeMessage
        )
    }
}
