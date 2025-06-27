import Foundation
@testable import Parley

extension MessageCollection {
    
    static func makeTestData(
        messages: [Message] = [.makeTestData(remoteId: 0), .makeTestData(remoteId: 1)],
        agent: Agent? = .none,
        stickyMessage: String? = .none,
        welcomeMessage: String? = .none
    ) -> MessageCollection {
        assert(messages.isEmpty == false, "Must contain at least one message")
                
        return MessageCollection(
            messages: messages,
            agent: agent,
            paging: Paging(
                before: String(messages.compactMap(\.remoteId).min()!),
                after: String(messages.compactMap(\.remoteId).max()!)
            ),
            stickyMessage: stickyMessage,
            welcomeMessage: welcomeMessage
        )
    }
}
