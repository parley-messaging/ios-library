import Testing
import Foundation
@testable import Parley

class MessagesPresenterSpy: MessagesPresenterProtocol {

    private(set) var setIsScrolledToBottomCallCount = 0
    private(set) var isScrolledToBottomLatestArgument: Bool = false
    
    private(set) var setWelcomeMessageCallCount = 0
    private(set) var presentSetSectionsCallCount = 0
    
    private(set) var presentStickyMessageCallCount = 0
    private(set) var didPresentAgentTypingCallsCount = 0
    private(set) var presentLoadingMessagesCallCount = 0

    private(set) var presentAddMessageCallCount = 0
    private(set) var presentAddLatestArgument: Message?
    
    private(set) var presentUpdateMessageCallCount = 0
    private(set) var presentUpdateLatestArgument: Message?
    
    private(set) var presentMessagesCallCount  = 0
    
    private(set) var presentQuickRepliesCallCount = 0
    private(set) var presentQuickRepliesLatestArgument: [String]?
    
    private(set) var presentHideQuickRepliesCallCount = 0
    
    private(set) var presentScrollToBotomCallCount = 0
    private(set) var presentScrollToBotomLatestArgument: Bool?
    
    func set(display: ParleyMessagesDisplay) { }
    
    func set(isScrolledToBottom: Bool) {
        setIsScrolledToBottomCallCount += 1
        isScrolledToBottomLatestArgument = isScrolledToBottom
    }
    
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
    
    func presentAdd(message: Message) {
        presentAddMessageCallCount += 1
        presentAddLatestArgument = message
    }
    
    func presentUpdate(message: Message) {
        presentUpdateMessageCallCount += 1
        presentUpdateLatestArgument = message
    }
    
    func presentMessages() {
        presentMessagesCallCount += 1
    }
    
    func present(quickReplies: [String]) {
        presentQuickRepliesCallCount += 1
        presentQuickRepliesLatestArgument = quickReplies
    }
    
    func presentHideQuickReplies() {
        presentHideQuickRepliesCallCount += 1
    }
    
    func presentScrollToBotom(animated: Bool) async {
        presentScrollToBotomCallCount += 1
        presentScrollToBotomLatestArgument = animated
    }
}
