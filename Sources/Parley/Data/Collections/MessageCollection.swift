import Foundation

struct MessageCollection: Equatable {

    struct Paging: Equatable {
        var before: String
        var after: String
    }

    var messages: [Message] = []
    var agent: Agent?
    var paging: Paging
    var stickyMessage: String?
    var welcomeMessage: String?
}
