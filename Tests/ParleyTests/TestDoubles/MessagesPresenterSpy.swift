import Testing
import Foundation
@testable import Parley

class MessagesPresenterSpy: MessagesPresenterProtocol {

    private(set) var setWelcomeMessageCallCount = 0
    private(set) var setMessagesCallCount = 0
    
    private(set) var presentStickyMessageCallCount = 0
    private(set) var didPresentAgentTypingCallsCount = 0
    private(set) var presentSetMessagesCallCount = 0
    private(set) var presentLoadingMessagesCallCount = 0
    private(set) var presentAddMessagesCallCount = 0
    private(set) var presentMessagesCallCount  = 0
    
    func set(welcomeMessage: String?) {
        setWelcomeMessageCallCount += 1
    }
    
    func set(messages: [Message]) {
        setMessagesCallCount += 1
    }
    
    func present(stickyMessage: String?) {
        presentStickyMessageCallCount += 1
    }
    
    func presentAgentTyping(_ isTyping: Bool) {
        didPresentAgentTypingCallsCount += 1
    }
    
    func presentSet(messages: [Message]) {
        presentSetMessagesCallCount += 1
    }
    
    func presentLoadingMessages(_ isLoading: Bool) {
        presentLoadingMessagesCallCount += 1
    }
    
    func presentAdd(messages: [Message], posistionsAdded: [ParleyChronologicalMessageCollection.Posisition]) {
        presentAddMessagesCallCount += 1
    }
    
    func presentMessages() {
        presentMessagesCallCount += 1
    }
    
    func set(display: ParleyMessagesDisplay) { }
}
