import Testing
import Foundation
@testable import Parley

class MessagesPresenterSpy: MessagesPresenterProtocol {

    private(set) var setWelcomeMessageCallCount = 0
    private(set) var presentSetSectionsCallCount = 0
    private(set) var presentStickyMessageCallCount = 0
    private(set) var didPresentAgentTypingCallsCount = 0
    private(set) var presentLoadingMessagesCallCount = 0

    private(set) var presentAddMessageCallCount = 0
    private(set) var presentAddLatestArguments: (Message, ParleyChronologicalMessageCollection.Position)?
    
    private(set) var presentUpdateMessageCallCount = 0
    private(set) var presentUpdateLatestArguments: (Message, ParleyChronologicalMessageCollection.Position)?
    
    private(set) var presentMessagesCallCount  = 0
    
    func set(display: ParleyMessagesDisplay) { }
    
    func set(welcomeMessage: String?) {
        setWelcomeMessageCallCount += 1
    }
    
    func set(sections: [ParleyChronologicalMessageCollection.Section]) {
        presentSetSectionsCallCount += 1
    }
    
    func present(stickyMessage: String?) {
        presentStickyMessageCallCount += 1
    }
    
    func presentAgentTyping(_ isTyping: Bool) {
        didPresentAgentTypingCallsCount += 1
    }
    
    func presentLoadingMessages(_ isLoading: Bool) {
        presentLoadingMessagesCallCount += 1
    }
    
    func presentAdd(message: Message, at posistion: ParleyChronologicalMessageCollection.Position) {
        presentAddMessageCallCount += 1
        presentAddLatestArguments = (message, posistion)
    }
    
    func presentUpdate(message: Message, at posistion: ParleyChronologicalMessageCollection.Position) {
        presentUpdateMessageCallCount += 1
        presentUpdateLatestArguments = (message, posistion)
    }
    
    func presentMessages() {
        presentMessagesCallCount += 1
    }
}
