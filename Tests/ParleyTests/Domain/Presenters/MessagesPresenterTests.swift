import Foundation
import Testing
@testable import Parley

@Suite("Messages Presenter Tests")
struct MessagesPresenterTests {
    
    private static let testSections: [[Message]] = [
        [],
        [.makeTestData(time: Date(timeIntSince1970: 1))],
        [
            .makeTestData(time: Date(timeIntSince1970: 1)),
            .makeTestData(time: Date(timeIntSince1970: 86401)),
        ],
        [
            .makeTestData(time: Date(timeIntSince1970: 1)),
            .makeTestData(time: Date(timeIntSince1970: 2))
        ],
        [
            .makeTestData(time: Date(timeIntSince1970: 1)),
            .makeTestData(time: Date(timeIntSince1970: 2)),
            .makeTestData(time: Date(timeIntSince1970: 86401)),
        ],
        [
            .makeTestData(time: Date(timeIntSince1970: 1)),
            .makeTestData(time: Date(timeIntSince1970: 2)),
            .makeTestData(time: Date(timeIntSince1970: 3)),
        ],
        [
            .makeTestData(time: Date(timeIntSince1970: 1)),
            .makeTestData(time: Date(timeIntSince1970: 2)),
            .makeTestData(time: Date(timeIntSince1970: 3)),
            .makeTestData(time: Date(timeIntSince1970: 86401)),
        ],
        [
            .makeTestData(time: Date(timeIntSince1970: 1)),
            .makeTestData(time: Date(timeIntSince1970: 2)),
            .makeTestData(time: Date(timeIntSince1970: 3)),
        ],
        [
            .makeTestData(time: Date(timeIntSince1970: 86401)),
            .makeTestData(time: Date(timeIntSince1970: 86402)),
            .makeTestData(time: Date(timeIntSince1970: 86403)),
        ],
        [
            .makeTestData(time: Date(timeIntSince1970: 1)),
            .makeTestData(time: Date(timeIntSince1970: 2)),
            .makeTestData(time: Date(timeIntSince1970: 3)),
            .makeTestData(time: Date(timeIntSince1970: 86401)),
            .makeTestData(time: Date(timeIntSince1970: 86402)),
            .makeTestData(time: Date(timeIntSince1970: 86403)),
        ]
    ]
    
    private let store: MessagesStore
    private let display: ParleyMessagesDisplaySpy
    private let presenter: MessagesPresenter
    private var collection: ParleyChronologicalMessageCollection
    
    private static let welcomeMessage = "Welcome!"
    private static let stickyMessage = "Sticky message"
    
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
        
        #expect(display.hasInterhactedWithDisplay == false)
    }
    
    @Test
    func presenter_ShouldhaveCorrectDefaultConfigurtion() {
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
    mutating func settingMessages_ShouldNotDisplayAnyMessages_WhenPresentMessagesIsNotCalled(messages: [Message]) {
        collection.set(messages: messages)
        
        presenter.set(sections: collection.sections)
        
        #expect(store.numberOfSections == 0)
        #expect(display.hasInterhactedWithDisplay == false, "Display should not be called when not calling presentMessages")
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
        let posistion = collection.add(message: message)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        // When
        presenter.presentAdd(message: message, at: posistion)
        
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
        let posistion = collection.add(message: message)
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        // When
        presenter.presentAdd(message: message, at: posistion)
        
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
        let position = collection.add(message: message)
        
        // When
        presenter.presentAdd(message: message, at: position)
        
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
        let position = collection.add(message: message)
        
        // When
        presenter.presentAdd(message: message, at: position)
        
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
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 86401))
        let position = collection.add(message: message)
        
        // When
        presenter.presentAdd(message: message, at: position)
        
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
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 86401))
        let position = collection.add(message: message)
        
        // When
        presenter.presentAdd(message: message, at: position)
        
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
        let message = Message.makeTestData(id: 2, time: Date(timeIntSince1970: 1), message: "First Message", type: .user, status: .pending)
        let pos = collection.add(message: message)
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        #expect(display.reloadCallCount == 1, "Should be 1 because we called presentMessages")
        
        let updatedMessage = Message.makeTestData(id: message.id, time: message.time, message: message.title, type: .user, status: .success)
        
        // When
        presenter.presentUpdate(message: updatedMessage, at: pos)
        
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
        let interactor = MessagesInteractor(
            presenter: presenter,
            messagesManager: MessagesManagerStub(),
            messageCollection: self.collection,
            messagesRepository: MessageRepositoryStub(),
            reachabilityProvider: ReachibilityProviderStub()
        )
        // When
        await interactor.handle(collection: collection, .all)
        
        // Expect
        #expect(presenter.welcomeMessage == Self.welcomeMessage)
        #expect(presenter.stickyMessage == Self.stickyMessage)
        #expect(display.reloadCallCount == 1)
    
        guard case .info = store[section: 0, row: 0] else { Issue.record("First cell should be the welcome message.") ; return }
        guard case .dateHeader = store[section: 1, row: 0] else { Issue.record("Second cell should be the date header.") ; return }
        #expect(store.getMessage(at: IndexPath(row: 1, section: 1)) == firstMessage, "Third cell should be the first message")
        #expect(store.getMessage(at: IndexPath(row: 2, section: 1)) == secondMessage, "Fourth cell should be the second message")
    }
    
    // MARK: Agent Typing
    
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
        #expect(presenter.currentSnapshot.sections[lastSectionIndex] == .typingIndicator)
        #expect(presenter.currentSnapshot.cells[lastSectionIndex][0] == .typingIndicator)
        #expect(presenter.currentSnapshot.cells[lastSectionIndex].count == 1)
        
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
    
    @MainActor
    mutating func presentAgentNotTyping_ShouldDoNothing_WhenAgentWasNotTyping() {
        presenter.presentAgentTyping(false)
        
        #expect(presenter.isAgentTyping)
        let lastSectionIndex = presenter.currentSnapshot.sections.endIndex - 1
        #expect(presenter.currentSnapshot.sections[lastSectionIndex] == .typingIndicator)
        #expect(presenter.currentSnapshot.cells[lastSectionIndex][0] == .typingIndicator)
        #expect(presenter.currentSnapshot.cells[lastSectionIndex].count == 1)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [
            IndexPath(row: 0, section: lastSectionIndex)
        ])
        
        #expect(display.reloadCallCount == 0)
        #expect(display.reloadRowsCallCount == 0)
        #expect(display.deleteRowsCallCount == 0)
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
