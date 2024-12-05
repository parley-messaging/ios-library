import Foundation
import Testing
@testable import Parley

@Suite("Messages Interactor Tests")
struct MessagesInteractorTests {
    
    private let presenter: MessagesPresenterSpy
    private let messagesManager: MessagesManagerStub
    private let interactor: MessagesInteractor
    private var reachibilityProvider: ReachibilityProviderStub
    private var messageRepositoryStub: MessageRepositoryStub
    
    init() {
        presenter = MessagesPresenterSpy()
        messagesManager = MessagesManagerStub()
        reachibilityProvider = ReachibilityProviderStub()
        messageRepositoryStub = MessageRepositoryStub()
        interactor = MessagesInteractor(
            presenter: presenter,
            messagesManager: messagesManager,
            messageCollection: ParleyChronologicalMessageCollection(calender: .current),
            messagesRepository: messageRepositoryStub,
            reachabilityProvider: reachibilityProvider
        )
        
        setDefaults()
    }
    
    private mutating func setDefaults() {
        reachibilityProvider.whenReachable(true)
        messagesManager.whenCanLoadMore(false)
    }
    
    @Test(
        "Should call `presentMessages` after `handleViewDidLoad` with any amount of messages.",
        arguments: [
            [],
            [Message.makeTestData()],
            [Message.makeTestData(), Message.makeTestData()]
        ]
    )
    @MainActor
    func handleViewDidLoad_ShouldCallPresentMessages(messages: [Message]) {
        #expect(presenter.presentMessagesCallCount == 0)
        messagesManager.messages = messages
        interactor.handleViewDidLoad()
        #expect(presenter.presentMessagesCallCount == 1)
    }
    
    @Test
    @MainActor
    func handleViewDidLoad_ShouldNotSetStickyMessage_WhenStickyMessageIsAbsent() {
        messagesManager.stickyMessage = nil
        #expect(presenter.presentStickyMessageCallCount == 0)
        interactor.handleViewDidLoad()
        #expect(presenter.presentStickyMessageCallCount == 0)
    }
    
    @Test
    @MainActor
    func handleViewDidLoad_ShouldNotSetStickyMessage_WhenWelcomeStickyIsEmpty() {
        messagesManager.stickyMessage = ""
        #expect(presenter.presentStickyMessageCallCount == 0)
        interactor.handleViewDidLoad()
        #expect(presenter.presentStickyMessageCallCount == 0)
    }
    
    @Test
    @MainActor
    func handleViewDidLoad_ShouldSetStickyMessage_WhenWelcomeStickyIsPresent() {
        messagesManager.stickyMessage = "We are closed!"
        #expect(presenter.presentStickyMessageCallCount == 0)
        #expect(presenter.presentMessagesCallCount == 0)
        
        interactor.handleViewDidLoad()
        
        #expect(presenter.presentStickyMessageCallCount == 1)
        #expect(presenter.presentMessagesCallCount == 1)
    }
    
    @Test
    mutating func handleMessageCollection() async {
        #expect(presenter.presentStickyMessageCallCount == 0)
        #expect(presenter.presentLoadingMessagesCallCount == 0)
        #expect(presenter.presentAddMessagesCallCount == 0)
        
        messagesManager.messages = [
            .makeTestData(id: 2),
            .makeTestData(id: 3)
        ]

        let collection = MessageCollection.makeTestData(
            messages: [.makeTestData(id: 0), .makeTestData(id: 1)],
            stickyMessage: "New Sticky Message",
            welcomeMessage: "Welcome!"
        )
        
        messagesManager.whenCanLoadMore(true)
        messageRepositoryStub.whenFindBefore(id: 2, .success(collection))
        
        await interactor.handleLoadMessages()
        
        #expect(presenter.presentStickyMessageCallCount == 1)
        #expect(presenter.presentLoadingMessagesCallCount == 2)
        #expect(presenter.presentAddMessagesCallCount == 1)
    }
    
    @Test
    @MainActor
    func handleAgentTyping() {
        #expect(interactor.agentTyping == false)
        #expect(presenter.didPresentAgentTypingCallsCount == 0)
        
        interactor.handleAgentBeganTyping()
        
        #expect(interactor.agentTyping)
        #expect(presenter.didPresentAgentTypingCallsCount == 1)
    }
    
    @Test
    @MainActor
    func handleAgentTyping_whenAgentIsAlreadyTyping() {
        interactor.handleAgentBeganTyping()
        #expect(presenter.didPresentAgentTypingCallsCount == 1)
        
        interactor.handleAgentBeganTyping()
        
        #expect(interactor.agentTyping)
        #expect(presenter.didPresentAgentTypingCallsCount == 1)
    }
    
    @Test
    @MainActor
    func handleLoadMessages_withoutNewMessages_ShouldNotBeInLoadingState() async {
        #expect(presenter.presentLoadingMessagesCallCount == 0)
        
        messagesManager.whenCanLoadMore(false)
        await interactor.handleLoadMessages()
        
        #expect(presenter.presentLoadingMessagesCallCount == 0)
    }
    
    @Test(
        arguments: [
            Result<MessageCollection, Error>.failure(CancellationError()),
            Result<MessageCollection, Error>.success(
                MessageCollection.makeTestData(messages: [.makeTestData(id: 0), .makeTestData(id: 1)])
            )
        ]
    )
    @MainActor
    mutating func handleLoadMessages_withNewMessages_ShouldBeInLoadingState(result: Result<MessageCollection, Error>) async {
        #expect(presenter.presentLoadingMessagesCallCount == 0)
        
        messagesManager.messages = [.makeTestData(id: 1)]
        messagesManager.whenCanLoadMore(true)
        messageRepositoryStub.whenFindBefore(id: 1, result)
        await interactor.handleLoadMessages()
        
        #expect(presenter.presentLoadingMessagesCallCount == 2)
    }
}
