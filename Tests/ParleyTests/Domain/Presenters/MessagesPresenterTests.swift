import Foundation
import Testing
@testable import Parley


fileprivate struct TestSections {
    static let testSections: [[Message]] = [
        [],
        [.makeTestData(time: Date(timeIntSince1970: 1))],
        [
            .makeTestData(time: Date(daysSince1970: 1)),
            .makeTestData(time: Date(daysSince1970: 2)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 1))
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 0)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 5)),
            .makeTestData(time: Date(daysSince1970: 2, offsetSeconds: 0)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 0)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 2)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 0)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 2)),
            .makeTestData(time: Date(daysSince1970: 2, offsetSeconds: 0)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 0)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 2)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 3)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 2)),
            .makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 3)),
            .makeTestData(time: Date(daysSince1970: 2, offsetSeconds: 1)),
            .makeTestData(time: Date(daysSince1970: 2, offsetSeconds: 2)),
            .makeTestData(time: Date(daysSince1970: 2, offsetSeconds: 3)),
        ]
    ]
}

@Suite("Messages Presenter Tests - Default welcome posisition")
@ParleyDomainActor
struct MessagesPresenterTests {
    
    private let store: MessagesStore
    private let display: ParleyMessagesDisplaySpy
    private let presenter: MessagesPresenter
    private var collection: ParleyChronologicalMessageCollection
    private let calendar: Calendar = .current
    
    private static let welcomeMessage = "Welcome!"
    private static let stickyMessage = "Sticky message"
    
    init() async {
        store = await MessagesStore()
        display = await ParleyMessagesDisplaySpy()
        presenter = await MessagesPresenter(
            store: store,
            display: display,
            usesAdaptiveWelcomePosistioning: false
        )
        collection = ParleyChronologicalMessageCollection(calendar: .current)
        
        await #expect(display.performBatchUpdatesCallCount == 0)
        
        await #expect(display.reloadCallCount == 0)
        
        await #expect(display.displayStickyMessageCallCount == 0)
        await #expect(display.displayHideStickyMessageCallCount == 0)
        
        await #expect(display.hasInteractedWithDisplay == false)
    }
    
    @Test
    func presenter_ShouldHaveCorrectDefaultConfiguration() async {
        #expect(presenter.isAgentTyping == false)
        #expect(presenter.welcomeMessage == nil)
        #expect(presenter.isLoadingMessages == false)
        
        #expect(presenter.currentSnapshot.agentTyping == false)
        #expect(presenter.currentSnapshot.welcomeMessage == nil)
        #expect(presenter.currentSnapshot.isLoading == false)
        
        await #expect(store.numberOfSections == 0)
    }
    
    @Test
    func presentMessageWithoutMessages_ShouldReloadDisplay() async {
        await presenter.presentMessages()
        await #expect(store.numberOfSections == 0)
        await #expect(display.reloadCallCount == 1)
    }
    
    @Test
    func setWelcomeMessage_ShouldSetWelcomeMessageOnCurrentSnapshot() {
        presenter.set(welcomeMessage: Self.welcomeMessage)
        #expect(presenter.welcomeMessage != nil)
        #expect(presenter.currentSnapshot.welcomeMessage == Self.welcomeMessage)
    }
    
    @Test
    func presentHideStickyMessage_ShouldHideStickyMessageImmediately() async {
        await presenter.present(stickyMessage: .none)
        await #expect(display.displayHideStickyMessageCallCount == 1)
    }
    
    @Test
    func presentStickyMessage_ShouldDisplayStickyMessageImmediately() async {
        await presenter.present(stickyMessage: Self.stickyMessage)
        await #expect(display.displayStickyMessageCallCount == 1)
    }
    
    @Test(arguments: TestSections.testSections)
    mutating func settingMessages_ShouldNotDisplayAnyMessages_WhenPresentMessagesIsNotCalled(messages: [Message]) async {
        collection.set(messages: messages)
        
        presenter.set(sections: collection.sections)
        
        await #expect(store.numberOfSections == 0)
        await #expect(display.hasInteractedWithDisplay == false, "Display should not be called when not calling presentMessages")
    }
    
    @Test
    func setEmptySectionWithWelcomeMessage_ShouldUpdateStoreAndDisplayReload() async {
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        
        await presenter.presentMessages()
        
        guard case .info = await store[section: 0, row: 0] else { Issue.record() ; return }
        await #expect(store.numberOfSections == 1)
        await #expect(store.getCells(inSection: 0).count == 1)
        await #expect(display.reloadCallCount == 1)
    }
    
    @Test
    mutating func insertMessageInEmptyChat_ShouldUpdateStoreAndInsertRowsOnDisplay() async {
        // Setup
        let message = Message.makeTestData(time: Date(timeIntSince1970: 1))
        _ = collection.add(message: message)
        await presenter.presentMessages()
        await #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        // When
        await presenter.presentAdd(message: message)
        
        // Then
        guard case .messages = await store[section: 0] else { Issue.record() ; return }
        guard case .message = await store[section: 0, row: 0] else { Issue.record() ; return }
        
        await #expect(store.numberOfSections == 1)
        await #expect(store.numberOfRows(inSection: 0) == 1)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    mutating func insertMessageInEmptyChatWithWelcomeMessage_ShouldUpdateStoreAndInsertRowOnDisplay() async {
        // Setup
        let message = Message.makeTestData(time: Date(timeIntSince1970: 1))
        _ = collection.add(message: message)
        
        presenter.set(welcomeMessage: Self.welcomeMessage)
        await presenter.presentMessages()
        await #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        // When
        await presenter.presentAdd(message: message)
        
        // Then
        guard case .info = await store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .messages = await store[section: 1] else { Issue.record() ; return }
        guard case .message = await store[section: 1, row: 0] else { Issue.record() ; return }
        
        await #expect(store.numberOfSections == 2)
        await #expect(store.numberOfRows(inSection: 0) == 1)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    mutating func insertMessageIntoTheSameSectionWithoutWelcomeMessage_ShouldUpdateStoreAndInsertRowOnDisplay() async {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(sections: collection.sections)
        await presenter.presentMessages()
        await #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 2))
        _ = collection.add(message: message)
        
        // When
        await presenter.presentAdd(message: message)
        
        // Then
        guard case .messages = await store[section: 0] else { Issue.record() ; return }
        guard case .message = await store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .message = await store[section: 0, row: 1] else { Issue.record() ; return }
        
        await #expect(store.numberOfSections == 1)
        await #expect(store.numberOfRows(inSection: 0) == 2)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    mutating func insertMessageIntoTheSameSectionWithWelcomeMessage() async {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        await presenter.presentMessages()
        await #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 2))
        _ = collection.add(message: message)
        
        // When
        await presenter.presentAdd(message: message)
        
        // Then
        guard case .info = await store[section: 0, row: 0] else { Issue.record() ; return }
        
        guard case .messages = await store[section: 1] else { Issue.record() ; return }
        guard case .message = await store[section: 1, row: 0] else { Issue.record() ; return }
        guard case .message = await store[section: 1, row: 1] else { Issue.record() ; return }
        
        await #expect(store.numberOfSections == 2)
        await #expect(store.numberOfRows(inSection: 0) == 1)
        await #expect(store.numberOfRows(inSection: 1) == 2)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    mutating func insertMessageIntoTheNewSectionWithoutWelcomeMessage() async {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(sections: collection.sections)
        await presenter.presentMessages()
        await #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let message = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 1))
        _ = collection.add(message: message)
        
        // When
        await presenter.presentAdd(message: message)
        
        // Then
        guard case .messages = await store[section: 0] else { Issue.record() ; return }
        guard case .message = await store[section: 0, row: 0] else { Issue.record() ; return }
        
        guard case .messages = await store[section: 1] else { Issue.record() ; return }
        guard case .message = await store[section: 1, row: 0] else { Issue.record() ; return }
        
        await #expect(store.numberOfSections == 2)
        await #expect(store.numberOfRows(inSection: 0) == 1)
        await #expect(store.numberOfRows(inSection: 1) == 1)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    mutating func insertMessageIntoTheNewSectionWithWelcomeMessage() async {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        await presenter.presentMessages()
        await #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let message = Message.makeTestData(time:  Date(daysSince1970: 1, offsetSeconds: 1))
        _ = collection.add(message: message)
        
        // When
        await presenter.presentAdd(message: message)
        
        // Then
        guard case .info = await store[section: 0, row: 0] else { Issue.record() ; return }
        
        guard case .messages = await store[section: 1] else { Issue.record() ; return }
        guard case .message = await store[section: 1, row: 0] else { Issue.record() ; return }
        
        guard case .messages = await store[section: 2] else { Issue.record() ; return }
        guard case .message = await store[section: 2, row: 0] else { Issue.record() ; return }
        
        await #expect(store.numberOfSections == 3)
        await #expect(store.numberOfRows(inSection: 0) == 1)
        await #expect(store.numberOfRows(inSection: 1) == 1)
        await #expect(store.numberOfRows(inSection: 2) == 1)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    mutating func updateMessage_ShouldUpdateStoreAndReloadRow() async {
        // Setup
        let message = Message.makeTestData(remoteId: 2, time: Date(timeIntSince1970: 1), title: nil, message: "First Message", type: .user, sendStatus: .pending)
        _ = collection.add(message: message)
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        await presenter.presentMessages()
        await #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let updatedMessage = Message.makeTestData(id: message.id, time: message.time, title: message.title, message: message.message, type: .user, sendStatus: .success)
        
        // When
        await presenter.presentUpdate(message: updatedMessage)
        
        // Then
        guard case .info = await store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .messages = await store[section: 1] else { Issue.record() ; return }
        guard case .message = await store[section: 1, row: 0] else { Issue.record() ; return }
        
        await #expect(store.numberOfSections == 2)
        await #expect(store.numberOfRows(inSection: 0) == 1)
        await #expect(store.numberOfRows(inSection: 1) == 1)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 1, "Should be unchanged")
        
        await #expect(store.getMessage(at: IndexPath(row: 0, section: 1))!.sendStatus == .success)
    }
    
    @Test
    mutating func test_ShouldBeCorrectlyConfigured_WhenStartingWithAMessageCollection() async {
        // Setup
        let firstMessage = createUserMessage("Hello!")
        let secondMessage = createUserMessage("How are you?")
        let collection = MessageCollection(
            messages: [firstMessage, secondMessage],
            agent: nil,
            paging: MessageCollection.Paging(before: "", after: "After"),
            stickyMessage: Self.stickyMessage,
            welcomeMessage: Self.welcomeMessage
        )
        self.collection.set(collection: collection)
        let messageRepositoryStub = MessageRepositoryStub()
        let interactor = await MessagesInteractor(
            messagesManager: MessagesManagerStub(),
            messageCollection: self.collection,
            messagesRepository: messageRepositoryStub,
            reachabilityProvider: ReachabilityProviderStub(),
            messageReadWorker: MessageReadWorker(messageRepository: messageRepositoryStub)
        )
        interactor.set(presenter: presenter)
        // When
        await interactor.handle(collection: collection, .all)
        
        // Expect
        #expect(presenter.welcomeMessage == Self.welcomeMessage)
        #expect(presenter.stickyMessage == Self.stickyMessage)
        await #expect(display.reloadCallCount == 1)
    
        guard case .info = await store[section: 0, row: 0] else { Issue.record("First cell should be the welcome message.") ; return }
        guard case .messages = await store[section: 1] else { Issue.record("Should be the next section.") ; return }
        await #expect(store.getMessage(at: IndexPath(row: 0, section: 1)) == firstMessage, "Third cell should be the first message")
        await #expect(store.getMessage(at: IndexPath(row: 1, section: 1)) == secondMessage, "Fourth cell should be the second message")
    }
    
    // MARK: - Agent Typing
    
    @Test(arguments: TestSections.testSections)
    mutating func presentAgentTyping_ShouldUpdateStoreAndInsertRow_WhenAgentWasNotTyping(messages: [Message]) async {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        // When
        await presenter.presentAgentTyping(true)
        
        // Then
        #expect(presenter.isAgentTyping)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count + 1)
        let lastSectionIndex = presenter.currentSnapshot.sections.endIndex - 1
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].sectionKind == .typingIndicator)
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].cells[0].kind == .typingIndicator)
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].cells.count == 1)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 0)
    }
    
    @Test(arguments: TestSections.testSections)
    @ParleyDomainActor
    mutating func presentAgentTyping_ShouldDoNothing_WhenAgentIsAlreadyTyping(messages: [Message]) async {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        // When
        await presenter.presentAgentTyping(true)
        await presenter.presentAgentTyping(true)
        
        // Then
        #expect(presenter.isAgentTyping)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count + 1)
        let lastSectionIndex = presenter.currentSnapshot.sections.endIndex - 1
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].sectionKind == .typingIndicator)
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].cells[0].kind == .typingIndicator)
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].cells.count == 1)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 0)
    }
    
    @Test(arguments: TestSections.testSections)
    mutating func presentAgentNotTyping_ShouldUpdateStoreAndDeleteRow_WhenAgentWasTyping(messages: [Message]) async {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        await presenter.presentMessages()
        await #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        await presenter.presentAgentTyping(true)
        await #expect(
            display.performBatchUpdatesCallCount == 1,
            "Presenting agent typing should trigger a betch update to insert the a section & row"
        )
        
        // When
        await presenter.presentAgentTyping(false)
        
        // Then
        #expect(presenter.isAgentTyping == false)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count)
       
        await #expect(display.performBatchUpdatesCallCount == 2)
        await #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test(arguments: TestSections.testSections)
    mutating func presentAgentNotTyping_ShouldDoNothing_WhenAgentWasNotTyping(messages: [Message]) async {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        #expect(presenter.isAgentTyping == false)
        
        // When
        await presenter.presentAgentTyping(false)
        
        // Then
        await #expect(display.hasInteractedWithDisplay == false)
    }
    
    // MARK: - Present Loading Messages -
    
    @Test(arguments: TestSections.testSections)
    mutating func presentLoading_ShouldUpdateStoreAndInsertRow_WhenIsNotLoading(messages: [Message]) async {
        #expect(presenter.currentSnapshot.sections.count == 0)
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        // When
        await presenter.presentLoadingMessages(true)
        
        // Then
        #expect(presenter.isLoadingMessages)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count + 1)
        #expect(presenter.currentSnapshot.sections[0].sectionKind == .loading)
        #expect(presenter.currentSnapshot.sections[0].cells[0].kind == .loading)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 0)
        await #expect(store[section: 0, row: 0] == .loading)
    }
    
    @Test(arguments: TestSections.testSections)
    mutating func presentLoading_ShouldDoNothing_WhenIsAlreadyLoading(messages: [Message]) async {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        // When
        await presenter.presentLoadingMessages(true)
        await presenter.presentLoadingMessages(true)
        
        // Then
        #expect(presenter.isLoadingMessages)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count + 1)
        #expect(presenter.currentSnapshot.sections[0].sectionKind == .loading)
        #expect(presenter.currentSnapshot.sections[0].cells[0].kind == .loading)
        
        await #expect(display.performBatchUpdatesCallCount == 1)
        await #expect(display.reloadCallCount == 0)
        await #expect(store[section: 0, row: 0] == .loading)
    }
    
    @Test(arguments: TestSections.testSections)
    mutating func presentNotLoading_ShouldUpdateStoreAndDeleteRow_WhenWasLoading(messages: [Message]) async {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        await presenter.presentLoadingMessages(true)
        await #expect(
            display.performBatchUpdatesCallCount == 1,
            "Should perform batch update due to a row insertion"
        )
        let loadingIndexPath = IndexPath(row: 0, section: 0)
        
        // When
        await presenter.presentLoadingMessages(false)
        
        // Then
        #expect(presenter.isLoadingMessages == false)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count)
       
        await #expect(
            display.performBatchUpdatesCallCount == 2,
            "Should perform batch update due to section deletion"
        )
        await #expect(display.reloadCallCount == 0)
        await #expect(store.numberOfSections == collection.sections.count)
    }
    
    @Test(arguments: TestSections.testSections)
    mutating func presentNotLoading_ShouldDoNothing_WhenIsNotLoading(messages: [Message]) async {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        #expect(presenter.isAgentTyping == false)
        
        // When
        await presenter.presentAgentTyping(false)
        
        // Then
        await #expect(display.hasInteractedWithDisplay == false)
    }
    
    @Test
    mutating func presentQuickReplies_ShouldDisplayQuickReplies() async {
        let quickReplies = ["Yes", "No"]
        
        await presenter.present(quickReplies: quickReplies)
        
        await #expect(display.displayQuickRepliesCallCount == 1)
        await #expect(display.displayQuickRepliesLatestArguments == quickReplies)
        await #expect(display.displayHideQuickRepliesCallCount == 0)
    }
    
    @Test
    mutating func presentHideQuickReplies_ShouldHideQuickReplies() async {
        await presenter.presentHideQuickReplies()
        
        await #expect(display.displayQuickRepliesCallCount == 0)
        await #expect(display.displayHideQuickRepliesCallCount == 1)
    }
    
    @Test(arguments: 0..<TestSections.testSections.count)
    mutating func presentSetMessages_ShouldResultInSectionsOrderOldestToNewest(index: Int) {
        let messages = TestSections.testSections[index]
        guard messages.isEmpty == false else { return }
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        var previousSectionDate: Date?
        for section in presenter.currentSnapshot.sections {
            guard let sectionDate = section.date else { continue }
            if previousSectionDate == nil {
                previousSectionDate = sectionDate
            } else {
                #expect(previousSectionDate! < sectionDate)
                previousSectionDate = sectionDate
            }
        }
    }
    
    @Test(arguments: 1..<TestSections.testSections.count)
    mutating func presentSetMessages_ShouldResultInMessagesOrderOldestToNewest(index: Int) throws {
        let messages = TestSections.testSections[index]
        print(messages.count)
        try #require(messages.isEmpty == false)
        
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        #expect(presenter.currentSnapshot.sections.isEmpty == false)
        var previousCellDate: Date?
        for section in presenter.currentSnapshot.sections {
            for cell in section.cells {
                guard let cellDate = cell.date else { continue }
                if previousCellDate == nil {
                    previousCellDate = cellDate
                } else {
                    #expect(previousCellDate! < cellDate)
                    previousCellDate = cellDate
                }
            }
        }
    }
}

extension MessagesPresenterTests {
    
    private func createUserMessage(_ message: String, date: Date = Date()) -> Message {
        return Message.makeTestData(time: date, message: message, type: .user)
    }
}
