import Foundation
import Testing
@testable import Parley

@Suite("Messages Presenter Tests")
struct MessagesPresenterTests {
    
    private static let testSections: [[Message]] = [
        [],
        [.makeTestData(time: Date(timeIntSince1970: 1))],
        [
            .makeTestData(time: Date(daysSince1970: 1)),
            .makeTestData(time: Date(daysSince1970: 2)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 1))
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offset: 0)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 5)),
            .makeTestData(time: Date(daysSince1970: 2, offset: 0)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offset: 0)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 2)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offset: 0)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 2)),
            .makeTestData(time: Date(daysSince1970: 2, offset: 0)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offset: 0)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 2)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 3)),
        ],
        [
            .makeTestData(time: Date(daysSince1970: 1, offset: 1)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 2)),
            .makeTestData(time: Date(daysSince1970: 1, offset: 3)),
            .makeTestData(time: Date(daysSince1970: 2, offset: 1)),
            .makeTestData(time: Date(daysSince1970: 2, offset: 2)),
            .makeTestData(time: Date(daysSince1970: 2, offset: 3)),
        ]
    ]
    
    private let store: MessagesStore
    private let display: ParleyMessagesDisplaySpy
    private let presenter: MessagesPresenter
    private var collection: ParleyChronologicalMessageCollection
    private let calendar: Calendar = .current
    
    private static let welcomeMessage = "Welcome!"
    private static let stickyMessage = "Sticky message"
    
    @MainActor
    init() {
        store = MessagesStore()
        display = ParleyMessagesDisplaySpy()
        presenter = MessagesPresenter(store: store, display: display)
        collection = ParleyChronologicalMessageCollection(calendar: .current)
        
        #expect(display.insertRowsCallCount == 0)
        #expect(display.insertRowsIndexPaths == nil)
        
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.deleteRowsIndexPaths == nil)
        
        #expect(display.reloadRowsCallCount == 0)
        #expect(display.reloadRowsIndexPaths == nil)
        
        #expect(display.reloadCallCount == 0)
        
        #expect(display.displayStickyMessageCallCount == 0)
        #expect(display.displayHideStickyMessageCallCount == 0)
        
        #expect(display.hasInteractedWithDisplay == false)
    }
    
    @Test
    func presenter_ShouldHaveCorrectDefaultConfiguration() {
        #expect(presenter.isAgentTyping == false)
        #expect(presenter.welcomeMessage == nil)
        #expect(presenter.isLoadingMessages == false)
        
        #expect(presenter.currentSnapshot.agentTyping == false)
        #expect(presenter.currentSnapshot.welcomeMessage == nil)
        #expect(presenter.currentSnapshot.isLoading == false)
        
        #expect(store.numberOfSections == 0)
    }
    
    @Test
    @MainActor
    func presentMessageWithoutMessages_ShouldReloadDisplay() {
        presenter.presentMessages()
        #expect(store.numberOfSections == 0)
        #expect(display.reloadCallCount == 1)
    }
    
    @Test
    func setWelcomeMessage_ShouldSetWelcomeMessageOnCurrentSnapshot() {
        presenter.set(welcomeMessage: Self.welcomeMessage)
        #expect(presenter.welcomeMessage != nil)
        #expect(presenter.currentSnapshot.welcomeMessage == Self.welcomeMessage)
    }
    
    @Test
    @MainActor
    func presentHideStickyMessage_ShouldHideStickyMessageImmediately() {
        presenter.present(stickyMessage: .none)
        #expect(display.displayHideStickyMessageCallCount == 1)
    }
    
    @Test
    @MainActor
    func presentStickyMessage_ShouldDisplayStickyMessageImmediately() {
        presenter.present(stickyMessage: Self.stickyMessage)
        #expect(display.displayStickyMessageCallCount == 1)
    }
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func settingMessages_ShouldNotDisplayAnyMessages_WhenPresentMessagesIsNotCalled(messages: [Message]) {
        collection.set(messages: messages)
        
        presenter.set(sections: collection.sections)
        
        #expect(store.numberOfSections == 0)
        #expect(display.hasInteractedWithDisplay == false, "Display should not be called when not calling presentMessages")
    }
    
    @Test
    @MainActor
    func setEmptySectionWithWelcomeMessage_ShouldUpdateStoreAndDisplayReload() {
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        
        presenter.presentMessages()
        
        guard case .info = store[section: 0, row: 0] else { Issue.record() ; return }
        #expect(store.numberOfSections == 1)
        #expect(store.getCells(inSection: 0).count == 1)
        #expect(display.reloadCallCount == 1)
    }
    
    @Test
    @MainActor
    mutating func insertMessageInEmptyChat_ShouldUpdateStoreAndInsertRowsOnDisplay() {
        // Setup
        let message = Message.makeTestData(time: Date(timeIntSince1970: 1))
        let position = collection.add(message: message)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        // When
        presenter.presentAdd(message: message)
        
        // Then
        guard case .dateHeader = store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 0, row: 1] else { Issue.record() ; return }
        
        #expect(store.numberOfSections == 1)
        #expect(store.numberOfRows(inSection: 0) == 2)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: 0),
            IndexPath(row: 1, section: 0),
        ])
        
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    @MainActor
    mutating func insertMessageInEmptyChatWithWelcomeMessage_ShouldUpdateStoreAndInsertRowOnDisplay() {
        // Setup
        let message = Message.makeTestData(time: Date(timeIntSince1970: 1))
        let position = collection.add(message: message)
        
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        // When
        presenter.presentAdd(message: message)
        
        // Then
        guard case .info = store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .dateHeader = store[section: 1, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 1, row: 1] else { Issue.record() ; return }
        
        #expect(store.numberOfSections == 2)
        #expect(store.numberOfRows(inSection: 0) == 1)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: 1),
            IndexPath(row: 1, section: 1),
        ])
        
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    @MainActor
    mutating func insertMessageIntoTheSameSectionWithoutWelcomeMessage_ShouldUpdateStoreAndInsertRowOnDisplay() {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 2))
        _ = collection.add(message: message)
        
        // When
        presenter.presentAdd(message: message)
        
        // Then
        guard case .dateHeader = store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 0, row: 1] else { Issue.record() ; return }
        guard case .message = store[section: 0, row: 2] else { Issue.record() ; return }
        
        #expect(store.numberOfSections == 1)
        #expect(store.numberOfRows(inSection: 0) == 3)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [IndexPath(row: 2, section: 0)])
        
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    @MainActor
    mutating func insertMessageIntoTheSameSectionWithWelcomeMessage() {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 2))
        _ = collection.add(message: message)
        
        // When
        presenter.presentAdd(message: message)
        
        // Then
        guard case .info = store[section: 0, row: 0] else { Issue.record() ; return }
        
        guard case .dateHeader = store[section: 1, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 1, row: 1] else { Issue.record() ; return }
        guard case .message = store[section: 1, row: 2] else { Issue.record() ; return }
        
        #expect(store.numberOfSections == 2)
        #expect(store.numberOfRows(inSection: 0) == 1)
        #expect(store.numberOfRows(inSection: 1) == 3)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [IndexPath(row: 2, section: 1)])
        
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    @MainActor
    mutating func insertMessageIntoTheNewSectionWithoutWelcomeMessage() {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let message = Message.makeTestData(time: Date(daysSince1970: 1, offset: 1))
        let position = collection.add(message: message)
        
        // When
        presenter.presentAdd(message: message)
        
        // Then
        guard case .dateHeader = store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 0, row: 1] else { Issue.record() ; return }
        
        guard case .dateHeader = store[section: 1, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 1, row: 1] else { Issue.record() ; return }
        
        #expect(store.numberOfSections == 2)
        #expect(store.numberOfRows(inSection: 0) == 2)
        #expect(store.numberOfRows(inSection: 1) == 2)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: 1),
            IndexPath(row: 1, section: 1)
        ])
        
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    @MainActor
    mutating func insertMessageIntoTheNewSectionWithWelcomeMessage() {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let message = Message.makeTestData(time:  Date(daysSince1970: 1, offset: 1))
        let position = collection.add(message: message)
        
        // When
        presenter.presentAdd(message: message)
        
        // Then
        guard case .info = store[section: 0, row: 0] else { Issue.record() ; return }
        
        guard case .dateHeader = store[section: 1, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 1, row: 1] else { Issue.record() ; return }
        
        guard case .dateHeader = store[section: 2, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 2, row: 1] else { Issue.record() ; return }
        
        #expect(store.numberOfSections == 3)
        #expect(store.numberOfRows(inSection: 0) == 1)
        #expect(store.numberOfRows(inSection: 1) == 2)
        #expect(store.numberOfRows(inSection: 2) == 2)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: 2),
            IndexPath(row: 1, section: 2)
        ])
        
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.reloadCallCount == 1, "Should be unchanged")
    }
    
    @Test
    @MainActor
    mutating func updateMessage_ShouldUpdateStoreAndReloadRow() {
        // Setup
        let message = Message.makeTestData(id: 2, time: Date(timeIntSince1970: 1), title: nil, message: "First Message", type: .user, status: .pending)
        _ = collection.add(message: message)
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let updatedMessage = Message.makeTestData(id: message.id, time: message.time, title: message.title, message: message.message, type: .user, status: .success)
        
        // When
        presenter.presentUpdate(message: updatedMessage)
        
        // Then
        guard case .info = store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .dateHeader = store[section: 1, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 1, row: 1] else { Issue.record() ; return }
        
        #expect(store.numberOfSections == 2)
        #expect(store.numberOfRows(inSection: 0) == 1)
        #expect(store.numberOfRows(inSection: 1) == 2)
        
        #expect(display.reloadRowsCallCount == 1)
        #expect(display.reloadRowsIndexPaths == [
            IndexPath(row: 1, section: 1)
        ])
        
        #expect(display.insertRowsCallCount == 0)
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.reloadCallCount == 1, "Should be unchanged")
        
        #expect(store.getMessage(at: IndexPath(row: 1, section: 1))!.status == .success)
    }
    
    @Test
    @MainActor
    mutating func test_ShouldBeCorrectlyConfigured_WhenStartingWithAMessageCollection() {
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
        let interactor = MessagesInteractor(
            presenter: presenter,
            messagesManager: MessagesManagerStub(),
            messageCollection: self.collection,
            messagesRepository: MessageRepositoryStub(),
            reachabilityProvider: ReachabilityProviderStub()
        )
        // When
        interactor.handle(collection: collection, .all)
        
        // Expect
        #expect(presenter.welcomeMessage == Self.welcomeMessage)
        #expect(presenter.stickyMessage == Self.stickyMessage)
        #expect(display.reloadCallCount == 1)
    
        guard case .info = store[section: 0, row: 0] else { Issue.record("First cell should be the welcome message.") ; return }
        guard case .dateHeader = store[section: 1, row: 0] else { Issue.record("Second cell should be the date header.") ; return }
        #expect(store.getMessage(at: IndexPath(row: 1, section: 1)) == firstMessage, "Third cell should be the first message")
        #expect(store.getMessage(at: IndexPath(row: 2, section: 1)) == secondMessage, "Fourth cell should be the second message")
    }
    
    // MARK: - Agent Typing
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func presentAgentTyping_ShouldUpdateStoreAndInsertRow_WhenAgentWasNotTyping(messages: [Message]) {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        // When
        presenter.presentAgentTyping(true)
        
        // Then
        #expect(presenter.isAgentTyping)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count + 1)
        let lastSectionIndex = presenter.currentSnapshot.sections.endIndex - 1
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].sectionKind == .typingIndicator)
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].cells[0].kind == .typingIndicator)
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].cells.count == 1)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: lastSectionIndex)
        ])
        
        #expect(display.reloadCallCount == 0)
        #expect(display.reloadRowsCallCount == 0)
        #expect(display.deleteRowsCallCount == 0)
    }
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func presentAgentTyping_ShouldDoNothing_WhenAgentIsAlreadyTyping(messages: [Message]) {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        // When
        presenter.presentAgentTyping(true)
        presenter.presentAgentTyping(true)
        
        // Then
        #expect(presenter.isAgentTyping)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count + 1)
        let lastSectionIndex = presenter.currentSnapshot.sections.endIndex - 1
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].sectionKind == .typingIndicator)
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].cells[0].kind == .typingIndicator)
        #expect(presenter.currentSnapshot.sections[lastSectionIndex].cells.count == 1)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: lastSectionIndex)
        ])
        
        #expect(display.reloadCallCount == 0)
        #expect(display.reloadRowsCallCount == 0)
        #expect(display.deleteRowsCallCount == 0)
    }
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func presentAgentNotTyping_ShouldUpdateStoreAndDeleteRow_WhenAgentWasTyping(messages: [Message]) {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        presenter.presentAgentTyping(true)
        #expect(display.insertRowsCallCount == 1, "Presenting agent typing should insert a row")
        let agentTypingIndexPath = display.insertRowsIndexPaths!.first!
        
        // When
        presenter.presentAgentTyping(false)
        
        // Then
        #expect(presenter.isAgentTyping == false)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count)
       
        #expect(display.deleteRowsCallCount == 1)
        #expect(display.deleteRowsIndexPaths == [agentTypingIndexPath])
        
        #expect(display.reloadCallCount == 1, "Should be unchanged")
        #expect(display.reloadRowsCallCount == 0)
        #expect(display.insertRowsCallCount == 1, "Should be unchanged")
    }
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func presentAgentNotTyping_ShouldDoNothing_WhenAgentWasNotTyping(messages: [Message]) {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        #expect(presenter.isAgentTyping == false)
        
        // When
        presenter.presentAgentTyping(false)
        
        // Then
        #expect(display.hasInteractedWithDisplay == false)
    }
    
    // MARK: - Present Loading Messages -
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func presentLoading_ShouldUpdateStoreAndInsertRow_WhenIsNotLoading(messages: [Message]) {
        #expect(presenter.currentSnapshot.sections.count == 0)
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        // When
        presenter.presentLoadingMessages(true)
        
        // Then
        #expect(presenter.isLoadingMessages)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count + 1)
        #expect(presenter.currentSnapshot.sections[0].sectionKind == .loading)
        #expect(presenter.currentSnapshot.sections[0].cells[0].kind == .loading)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: 0)
        ])
        
        #expect(store[section: 0, row: 0] == .loading)
        
        #expect(display.reloadCallCount == 0)
        #expect(display.reloadRowsCallCount == 0)
        #expect(display.deleteRowsCallCount == 0)
    }
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func presentLoading_ShouldDoNothing_WhenIsAlreadyLoading(messages: [Message]) {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        // When
        presenter.presentLoadingMessages(true)
        presenter.presentLoadingMessages(true)
        
        // Then
        #expect(presenter.isLoadingMessages)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count + 1)
        #expect(presenter.currentSnapshot.sections[0].sectionKind == .loading)
        #expect(presenter.currentSnapshot.sections[0].cells[0].kind == .loading)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: 0)
        ])
        
        #expect(store[section: 0, row: 0] == .loading)
        
        #expect(display.reloadCallCount == 0)
        #expect(display.reloadRowsCallCount == 0)
        #expect(display.deleteRowsCallCount == 0)
    }
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func presentNotLoading_ShouldUpdateStoreAndDeleteRow_WhenWasLoading(messages: [Message]) {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        
        presenter.presentLoadingMessages(true)
        #expect(display.insertRowsCallCount == 1, "Presenting agent typing should insert a row")
        let loadingIndexPath = IndexPath(row: 0, section: 0)
        
        // When
        presenter.presentLoadingMessages(false)
        
        // Then
        #expect(presenter.isLoadingMessages == false)
        #expect(presenter.currentSnapshot.sections.count == collection.sections.count)
       
        #expect(display.deleteRowsCallCount == 1)
        #expect(display.deleteRowsIndexPaths == [loadingIndexPath])
        
        #expect(store.numberOfSections == collection.sections.count)
        
        #expect(display.reloadCallCount == 0)
        #expect(display.reloadRowsCallCount == 0)
        #expect(display.insertRowsCallCount == 1)
    }
    
    @Test(arguments: Self.testSections)
    @MainActor
    mutating func presentNotLoading_ShouldDoNothing_WhenIsNotLoading(messages: [Message]) {
        // Setup
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        #expect(presenter.isAgentTyping == false)
        
        // When
        presenter.presentAgentTyping(false)
        
        // Then
        #expect(display.hasInteractedWithDisplay == false)
    }
    
    @Test
    @MainActor
    mutating func presentQuickReplies_ShouldDisplayQuickReplies() {
        let quickReplies = ["Yes", "No"]
        
        presenter.present(quickReplies: quickReplies)
        
        #expect(display.displayQuickRepliesCallCount == 1)
        #expect(display.displayQuickRepliesLatestArguments == quickReplies)
        #expect(display.displayHideQuickRepliesCallCount == 0)
    }
    
    @Test
    @MainActor
    mutating func presentHideQuickReplies_ShouldHideQuickReplies() {
        presenter.presentHideQuickReplies()
        
        #expect(display.displayQuickRepliesCallCount == 0)
        #expect(display.displayHideQuickRepliesCallCount == 1)
    }
    
    @Test(arguments: 0..<Self.testSections.count)
    mutating func presentSetMessages_ShouldResultInSectionsOrderOldestToNewest(index: Int) {
        let messages = Self.testSections[index]
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
    
    @Test(arguments: 1..<Self.testSections.count)
    @MainActor
    mutating func presentSetMessages_ShouldResultInMessagesOrderOldestToNewest(index: Int) throws {
        let messages = Self.testSections[index]
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
        let userMessage = Message()
        userMessage.message = message
        userMessage.time = date
        userMessage.type = .user
        return userMessage
    }
}
