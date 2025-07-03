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
    
    init() async {
        presenter = MessagesPresenterSpy()
        messagesManager = MessagesManagerStub()
        reachabilityProvider = ReachabilityProviderStub()
        messageRepositoryStub = MessageRepositoryStub()
        interactor = await MessagesInteractor(
            presenter: presenter,
            messagesManager: messagesManager,
            messageCollection: ParleyChronologicalMessageCollection(calendar: .current),
            messagesRepository: messageRepositoryStub,
            reachabilityProvider: reachabilityProvider
        )
        
        await setDefaults()
    }
    
    private mutating func setDefaults() async {
        reachabilityProvider.whenReachable(true)
        await messagesManager.whenCanLoadMore(false)
    }
    
    @Test(
        "Should call `presentMessages` after `handleViewDidLoad` with any amount of messages.",
        arguments: [
            [],
            [Message.makeTestData()],
            [Message.makeTestData(), Message.makeTestData()]
        ]
    )
    func handleViewDidLoad_ShouldCallPresentMessages(messages: [Message]) async {
        #expect(await presenter.presentMessagesCallCount == 0)
        #expect(await presenter.presentSetSectionsCallCount == 0)
        
        await messagesManager.setMessages(messages)
        await interactor.handleViewDidLoad()
        
        #expect(await presenter.presentSetSectionsCallCount == 1)
        #expect(await presenter.presentMessagesCallCount == 1)
        #expect(await presenter.presentQuickRepliesCallCount == 0)
        #expect(await presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test(arguments: [
        [
            Message.makeTestData(remoteId: 0, quickReplies: ["Yes"], type: .agent)
        ],
        [
            Message.makeTestData(remoteId: 0, message: "Would you like to order", type: .agent),
            Message.makeTestData(remoteId: 1, quickReplies: ["Yes"], type: .agent),
        ]
    ])
    func handleViewDidLoad_ShouldPresentQuickReplies_WhenQuickReplyMessageIsTheLastMessage(messages: [Message]) async {
        #expect(await presenter.presentMessagesCallCount == 0)
        #expect(await presenter.presentSetSectionsCallCount == 0)
        
        await messagesManager.setMessages(messages)
        await interactor.handleViewDidLoad()
        
        #expect(await presenter.presentQuickRepliesCallCount == 1)
        #expect(await presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test(arguments: [
        [
            Message.makeTestData(remoteId: 0, quickReplies: ["Yes"], type: .agent),
            Message.makeTestData(remoteId: 0, message: "Describe your issue", type: .agent),
        ],
        [
            Message.makeTestData(remoteId: 0, message: "Do you want to order", type: .agent),
            Message.makeTestData(remoteId: 0, quickReplies: ["Yes"], type: .agent),
            Message.makeTestData(remoteId: 0, message: "Yes I want to order", type: .user),
        ]
    ])

    func handleViewDidLoad_ShouldIgnoreQuickReplies_WhenQuickReplyMessageIsNotTheLastMessage(messages: [Message]) async {
        #expect(await presenter.presentMessagesCallCount == 0)
        #expect(await presenter.presentSetSectionsCallCount == 0)
        
        await messagesManager.setMessages(messages)
        await interactor.handleViewDidLoad()
        
        #expect(await presenter.presentQuickRepliesCallCount == 0)
        #expect(await presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test
    func handleViewDidLoad_ShouldNotSetStickyMessage_WhenStickyMessageIsAbsent() async {
        await messagesManager.setStickyMessage(nil)
        #expect(await presenter.presentStickyMessageCallCount == 0)
        await interactor.handleViewDidLoad()
        #expect(await presenter.presentStickyMessageCallCount == 0)
    }
    
    @Test
    func handleViewDidLoad_ShouldNotSetStickyMessage_WhenWelcomeStickyIsEmpty() async {
        await messagesManager.setStickyMessage("")
        #expect(await presenter.presentStickyMessageCallCount == 0)
        await interactor.handleViewDidLoad()
        #expect(await presenter.presentStickyMessageCallCount == 0)
    }
    
    @Test
    func handleViewDidLoad_ShouldSetStickyMessage_WhenWelcomeStickyIsPresent() async {
        await messagesManager.setStickyMessage("We are closed!")
        #expect(await presenter.presentStickyMessageCallCount == 0)
        #expect(await presenter.presentMessagesCallCount == 0)
        
        await interactor.handleViewDidLoad()
        
        #expect(await presenter.presentStickyMessageCallCount == 1)
        #expect(await presenter.presentMessagesCallCount == 1)
    }
    
    @Test
    mutating func handleMessageCollection_ShouldPresentStickyMessageAndLoadingAndSetSections() async {
        #expect(await presenter.presentStickyMessageCallCount == 0)
        #expect(await presenter.presentLoadingMessagesCallCount == 0)
        #expect(await presenter.presentSetSectionsCallCount == 0)
        
        await messagesManager.setMessages([
            .makeTestData(remoteId: 2, time: Date(timeIntervalSince1970: 2)),
            .makeTestData(remoteId: 3, time: Date(timeIntervalSince1970: 3))
        ])

        let collection = MessageCollection.makeTestData(
            messages: [
                .makeTestData(remoteId: 0, time: Date(timeIntervalSince1970: 1)),
                .makeTestData(remoteId: 1, time: Date(timeIntervalSince1970: 2))
            ],
            stickyMessage: "New Sticky Message",
            welcomeMessage: "Welcome!"
        )
        
        await messagesManager.whenCanLoadMore(true)
        await messageRepositoryStub.whenFindBefore(id: 2, .success(collection))
        
        await interactor.handleLoadMessages()
        
        #expect(await presenter.presentStickyMessageCallCount == 1)
        #expect(await presenter.presentLoadingMessagesCallCount == 2)
        #expect(await presenter.presentSetSectionsCallCount == 1)
    }
    
    @Test
    mutating func handleMessageCollection_ShouldIgnoreQuickReplies_WhenNotTheLastMessage() async {
        #expect(await presenter.presentStickyMessageCallCount == 0)
        #expect(await presenter.presentLoadingMessagesCallCount == 0)
        #expect(await presenter.presentSetSectionsCallCount == 0)
        
        await messagesManager.setMessages([
            .makeTestData(remoteId: 4, time: Date(timeIntervalSince1970: 4)),
            .makeTestData(remoteId: 5, time: Date(timeIntervalSince1970: 5))
        ])

        let collection = MessageCollection.makeTestData(
            messages: [
                .makeTestData(remoteId: 1, time: Date(timeIntervalSince1970: 1)),
                .makeTestData(remoteId: 2, time: Date(timeIntervalSince1970: 2), quickReplies: ["Yes", "No"]),
                .makeTestData(remoteId: 3, time: Date(timeIntervalSince1970: 3))
            ],
            stickyMessage: "New Sticky Message",
            welcomeMessage: "Welcome!"
        )
        
        await messagesManager.whenCanLoadMore(true)
        await messageRepositoryStub.whenFindBefore(id: 4, .success(collection))
        
        await interactor.handleLoadMessages()
        
        #expect(await presenter.presentQuickRepliesCallCount == 0)
        #expect(await presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test
    func handleAgentTyping() async {
        #expect(await interactor.agentTyping == false)
        #expect(await presenter.didPresentAgentTypingCallsCount == 0)
        
        await interactor.handleAgentBeganTyping()
        
        #expect(await interactor.agentTyping)
        #expect(await presenter.didPresentAgentTypingCallsCount == 1)
    }
    
    @Test
    func handleAgentTyping_whenAgentIsAlreadyTyping() async {
        await interactor.handleAgentBeganTyping()
        #expect(await presenter.didPresentAgentTypingCallsCount == 1)
        
        await interactor.handleAgentBeganTyping()
        
        #expect(await interactor.agentTyping)
        #expect(await presenter.didPresentAgentTypingCallsCount == 1)
    }
    
    @Test
    func handleLoadMessages_WithoutNewMessages_ShouldNotBeInLoadingState() async {
        #expect(await presenter.presentLoadingMessagesCallCount == 0)
        
        await messagesManager.whenCanLoadMore(false)
        await interactor.handleLoadMessages()
        
        #expect(await presenter.presentLoadingMessagesCallCount == 0)
    }
    
    @Test(
        arguments: [
            Result<MessageCollection, Error>.failure(CancellationError()),
            Result<MessageCollection, Error>.success(
                MessageCollection.makeTestData(messages: [.makeTestData(remoteId: 0), .makeTestData(remoteId: 1)])
            )
        ]
    )
    mutating func handleLoadMessages_withNewMessages_ShouldBeInLoadingState(result: Result<MessageCollection, Error>) async {
        #expect(await presenter.presentLoadingMessagesCallCount == 0)
        
        await messagesManager.setMessages([.makeTestData(remoteId: 1)])
        await messagesManager.whenCanLoadMore(true)
        await messageRepositoryStub.whenFindBefore(id: 1, result)
        await interactor.handleLoadMessages()
        
        #expect(await presenter.presentLoadingMessagesCallCount == 2)
    }
    
    // MARK: Quick Replies
    
    @Test(arguments: [
        ["Yes"],
        ["Yes", "No"],
        ["Yes", "No", "Maybe"],
    ])
    mutating func handleNewMessage_ShouldPresentQuickReplies_WhenMessageHasQuickReplies(quickReplies: [String]) async {
        let message = Message.makeTestData(time: Date(), quickReplies: quickReplies, type: .agent)
        
        await interactor.handleNewMessage(message)
        
        #expect(await presenter.presentMessagesCallCount == 0)
        #expect(await presenter.presentSetSectionsCallCount == 0)
        #expect(await presenter.presentAddMessageCallCount == 0)
        #expect(await presenter.presentQuickRepliesCallCount == 1)
        #expect(await presenter.presentQuickRepliesLatestArgument == quickReplies)
        #expect(await presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test
    mutating func handleNewMessage_ShouldPresentQuickReplies_WhenQuickRepliesWereAlreadyPresentedWithADiffentValue() async {
        // Setup
        let oldQuickreplies = ["Old", "Reply"]
        let newQuickreplies = ["New", "Reply"]
        let oldQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: oldQuickreplies, type: .agent)
        await interactor.handleNewMessage(oldQuickReplyMessage)
        
        // When
        let newQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: newQuickreplies, type: .agent)
        await interactor.handleNewMessage(newQuickReplyMessage)
        
        // Then
        #expect(await presenter.presentQuickRepliesCallCount == 2)
        #expect(await presenter.presentQuickRepliesLatestArgument == newQuickreplies)
        #expect(await presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test
    mutating func handleNewMessage_ShouldIgnoreQuickReplyMessage_WhenQuickRepliesWereAlreadyPresentedWithTheSameValue() async {
        // Setup
        let quickreplies = ["Old", "Reply"]
        let oldQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: quickreplies, type: .agent)
        await interactor.handleNewMessage(oldQuickReplyMessage)
        
        // When
        let newQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: quickreplies, type: .agent)
        await interactor.handleNewMessage(newQuickReplyMessage)
        
        // Then
        #expect(await presenter.presentQuickRepliesCallCount == 1)
        #expect(await presenter.presentQuickRepliesLatestArgument == quickreplies)
        #expect(await presenter.presentHideQuickRepliesCallCount == 0)
    }
    
    @Test
    mutating func handleNewMessage_ShouldHideQuickReplyMessage_WhenQuickRepliesWerePreviouslyPresented() async {
        // Setup
        let quickReplies = ["Yes", "No"]
        let oldQuickReplyMessage = Message.makeTestData(time: Date(), quickReplies: quickReplies, type: .agent)
        await interactor.handleNewMessage(oldQuickReplyMessage)
        
        // When
        let newAgentMessage = Message.makeTestData(time: Date(), message: "Hello", type: .agent)
        await interactor.handleNewMessage(newAgentMessage)
        
        // Then
        #expect(await presenter.presentQuickRepliesCallCount == 1)
        #expect(await presenter.presentHideQuickRepliesCallCount == 1)
    }
}
