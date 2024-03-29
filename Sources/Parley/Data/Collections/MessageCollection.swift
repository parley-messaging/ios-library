import Foundation

struct MessageCollection: Codable, Equatable {

    struct Paging: Codable, Equatable {
        var before: String
        var after: String

        init(before: String, after: String) {
            self.before = before
            self.after = after
        }
    }

    var messages: [Message] = []
    var agent: Agent?
    var paging: Paging
    var stickyMessage: String?
    var welcomeMessage: String?

    init(
        messages: [Message] = [],
        agent: Agent?,
        paging: Paging,
        stickyMessage: String?,
        welcomeMessage: String?
    ) {
        self.messages = messages
        self.agent = agent
        self.paging = paging
        self.stickyMessage = stickyMessage
        self.welcomeMessage = welcomeMessage
    }

    enum CodingKeys: String, CodingKey {
        case messages = "data"
        case agent
        case paging
        case stickyMessage
        case welcomeMessage
    }

}
