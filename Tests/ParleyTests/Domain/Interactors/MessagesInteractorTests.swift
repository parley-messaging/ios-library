import Foundation
import Testing
@testable import Parley

@Suite("Messages Interactor Tests")
struct MessagesInteractorTests {
    
    private let presenter: MessagesPresenterSpy
    private let messagesManager: MessagesManagerStub
    private let interactor: MessagesInteractor
    private var reachabilityProvider: ReachabilityProviderStub
    private var messageRepositoryStub: MessageRepositoryStub
    
    init() {
        presenter = MessagesPresenterSpy()
        messagesManager = MessagesManagerStub()
        reachabilityProvider = ReachabilityProviderStub()
        messageRepositoryStub = MessageRepositoryStub()
        interactor = MessagesInteractor(
            presenter: presenter,
            messagesManager: messagesManager,
            messageCollection: ParleyChronologicalMessageCollection(calendar: .current),
            messagesRepository: messageRepositoryStub,
            reachabilityProvider: reachabilityProvider
        )
        
        setDefaults()
    }
    
    private mutating func setDefaults() {
        reachabilityProvider.whenReachable(true)
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
        #expect(presenter.presentSetSectionsCallCount == 0)
        
        messagesManager.messages = messages
        interactor.handleViewDidLoad()
        
        #expect(presenter.presentSetSectionsCallCount == 1)
        #expect(presenter.presentMessagesCallCount == 1)
        #expect(presenter.presentQuickRepliesCallCount == 0)
        #expect(presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test(arguments: [
        [
            Message.makeTestData(id: 0, quickReplies: ["Yes"], type: .agent)
        ],
        [
            Message.makeTestData(id: 0, message: "Would you like to order", type: .agent),
            Message.makeTestData(id: 1, quickReplies: ["Yes"], type: .agent),
        ]
    ])
    @MainActor
    func handleViewDidLoad_ShouldPresentQuickReplies_WhenQuickReplyMessageIsTheLastMessage(messages: [Message]) {
        #expect(presenter.presentMessagesCallCount == 0)
        #expect(presenter.presentSetSectionsCallCount == 0)
        
        messagesManager.messages = messages
        interactor.handleViewDidLoad()
        
        #expect(presenter.presentQuickRepliesCallCount == 1)
        #expect(presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test(arguments: [
        [
            Message.makeTestData(id: 0, quickReplies: ["Yes"], type: .agent),
            Message.makeTestData(id: 0, message: "Describe your issue", type: .agent),
        ],
        [
            Message.makeTestData(id: 0, message: "Do you want to order", type: .agent),
            Message.makeTestData(id: 0, quickReplies: ["Yes"], type: .agent),
            Message.makeTestData(id: 0, message: "Yes I want to order", type: .user),
        ]
    ])
    @MainActor
    func handleViewDidLoad_ShouldIgnoreQuickReplies_WhenQuickReplyMessageIsNotTheLastMessage(messages: [Message]) {
        #expect(presenter.presentMessagesCallCount == 0)
        #expect(presenter.presentSetSectionsCallCount == 0)
        
        messagesManager.messages = messages
        interactor.handleViewDidLoad()
        
        #expect(presenter.presentQuickRepliesCallCount == 0)
        #expect(presenter.presentHideQuickRepliesCallCount == 0)
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
    mutating func handleMessageCollection_ShouldPresentStickyMessageAndLoadingAndSetSections() async {
        #expect(presenter.presentStickyMessageCallCount == 0)
        #expect(presenter.presentLoadingMessagesCallCount == 0)
        #expect(presenter.presentSetSectionsCallCount == 0)
        
        messagesManager.messages = [
            .makeTestData(id: 2, time: Date(timeIntervalSince1970: 2)),
            .makeTestData(id: 3, time: Date(timeIntervalSince1970: 3))
        ]

        let collection = MessageCollection.makeTestData(
            messages: [
                .makeTestData(id: 0, time: Date(timeIntervalSince1970: 1)),
                .makeTestData(id: 1, time: Date(timeIntervalSince1970: 2))
            ],
            stickyMessage: "New Sticky Message",
            welcomeMessage: "Welcome!"
        )
        
        messagesManager.whenCanLoadMore(true)
        messageRepositoryStub.whenFindBefore(id: 2, .success(collection))
        
        await interactor.handleLoadMessages()
        
        #expect(presenter.presentStickyMessageCallCount == 1)
        #expect(presenter.presentLoadingMessagesCallCount == 2)
        #expect(presenter.presentSetSectionsCallCount == 1)
    }
    
    @Test
    mutating func handleMessageCollection_ShouldIgnoreQuickReplies_WhenNotTheLastMessage() async {
        #expect(presenter.presentStickyMessageCallCount == 0)
        #expect(presenter.presentLoadingMessagesCallCount == 0)
        #expect(presenter.presentSetSectionsCallCount == 0)
        
        messagesManager.messages = [
            .makeTestData(id: 4, time: Date(timeIntervalSince1970: 4)),
            .makeTestData(id: 5, time: Date(timeIntervalSince1970: 5))
        ]

        let collection = MessageCollection.makeTestData(
            messages: [
                .makeTestData(id: 1, time: Date(timeIntervalSince1970: 1)),
                .makeTestData(id: 2, time: Date(timeIntervalSince1970: 2), quickReplies: ["Yes", "No"]),
                .makeTestData(id: 3, time: Date(timeIntervalSince1970: 3))
            ],
            stickyMessage: "New Sticky Message",
            welcomeMessage: "Welcome!"
        )
        
        messagesManager.whenCanLoadMore(true)
        messageRepositoryStub.whenFindBefore(id: 4, .success(collection))
        
        await interactor.handleLoadMessages()
        
        #expect(presenter.presentQuickRepliesCallCount == 0)
        #expect(presenter.presentHideQuickRepliesCallCount == 0)
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
    func handleLoadMessages_WithoutNewMessages_ShouldNotBeInLoadingState() async {
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
    
    // MARK: Quick Replies
    
    @Test(arguments: [
        ["Yes"],
        ["Yes", "No"],
        ["Yes", "No", "Maybe"],
    ])
    @MainActor
    mutating func handleNewMessage_ShouldPresentQuickReplies_WhenMessageHasQuickReplies(quickReplies: [String]) {
        let message = Message.makeTestData(time: Date(), quickReplies: quickReplies, type: .agent)
        
        interactor.handleNewMessage(message)
        
        #expect(presenter.presentMessagesCallCount == 0)
        #expect(presenter.presentSetSectionsCallCount == 0)
        #expect(presenter.presentAddMessageCallCount == 0)
        #expect(presenter.presentQuickRepliesCallCount == 1)
        #expect(presenter.presentQuickRepliesLatestArgument == quickReplies)
        #expect(presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test
    @MainActor
    mutating func handleNewMessage_ShouldPresentQuickReplies_WhenQuickRepliesWereAlreadyPresentedWithADiffentValue() {
        // Setup
        let oldQuickreplies = ["Old", "Reply"]
        let newQuickreplies = ["New", "Reply"]
        let oldQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: oldQuickreplies, type: .agent)
        interactor.handleNewMessage(oldQuickReplyMessage)
        
        // When
        let newQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: newQuickreplies, type: .agent)
        interactor.handleNewMessage(newQuickReplyMessage)
        
        // Then
        #expect(presenter.presentQuickRepliesCallCount == 2)
        #expect(presenter.presentQuickRepliesLatestArgument == newQuickreplies)
        #expect(presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test
    @MainActor
    mutating func handleNewMessage_ShouldIgnoreQuickReplyMessage_WhenQuickRepliesWereAlreadyPresentedWithTheSameValue() {
        // Setup
        let quickreplies = ["Old", "Reply"]
        let oldQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: quickreplies, type: .agent)
        interactor.handleNewMessage(oldQuickReplyMessage)
        
        // When
        let newQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: quickreplies, type: .agent)
        interactor.handleNewMessage(newQuickReplyMessage)
        
        // Then
        #expect(presenter.presentQuickRepliesCallCount == 1)
        #expect(presenter.presentQuickRepliesLatestArgument == quickreplies)
        #expect(presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test
    @MainActor
    mutating func handleNewMessage_ShouldHideQuickReplyMessage_WhenQuickRepliesWerePreviouslyPresented() {
        // Setup
        let quickReplies = ["Yes", "No"]
        let oldQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: quickReplies, type: .agent)
        interactor.handleNewMessage(oldQuickReplyMessage)
        
        // When
        let newAgentMessage = Message.makeTestData(time: Date(), message: "Hello", type: .agent)
        interactor.handleNewMessage(newAgentMessage)
        
        // Then
        #expect(presenter.presentQuickRepliesCallCount == 1)
        #expect(presenter.presentHideQuickRepliesCallCount == 1)
    }
}
