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
        collection = ParleyChronologicalMessageCollection(calender: .current)
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
    func setWelcomeMessage() {
        #expect(presenter.welcomeMessage == nil)
        #expect(presenter.currentSnapshot.welcomeMessage == nil)
        presenter.set(welcomeMessage: Self.welcomeMessage)
        #expect(presenter.welcomeMessage != nil)
        #expect(presenter.currentSnapshot.welcomeMessage == Self.welcomeMessage)
    }
    
    @Test
    @MainActor
    func presentStickyNoMessage() {
        #expect(display.displayHideStickyMessageCallCount == 0)
        presenter.present(stickyMessage: .none)
        #expect(display.displayHideStickyMessageCallCount == 1)
    }
    
    @Test
    @MainActor
    func presentStickyMessage() {
        #expect(display.displayStickyMessageCallCount == 0)
        presenter.present(stickyMessage: Self.stickyMessage)
        #expect(display.displayStickyMessageCallCount == 1)
    }
    
    @Test(arguments: Self.testSections)
    mutating func setEmptySections(messages: [Message]) {
        collection.set(messages: messages)
        presenter.set(sections: collection.sections)
        #expect(store.numberOfSections == 0)
        #expect(display.hasInterhactedWithDisplay == false, "Display should not be called when not calling presentMessages")
    }
    
    @Test()
    @MainActor
    func setEmptySectionWithWelcomeMessage() {
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
    mutating func insertMessageInEmptyChat() {
        #expect(store.numberOfSections == 0)
        #expect(display.insertRowsCallCount == 0)
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 1))
        let posistion = collection.add(message: message)
        presenter.presentMessages()
        presenter.presentAdd(message: message, at: posistion)
        
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
        #expect(display.reloadCallCount == 1, "Should be one because we called presentMessages")
    }
    
    @Test
    @MainActor
    mutating func insertMessageInEmptyChatWithWelcomeMessage() {
        #expect(store.numberOfSections == 0)
        #expect(display.insertRowsCallCount == 0)
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 1))
        let posistion = collection.add(message: message)
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.presentMessages()
        presenter.presentAdd(message: message, at: posistion)
        
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
        #expect(display.reloadCallCount == 1, "Should be one because we called presentMessages")
    }
    
    @Test
    @MainActor
    mutating func insertMessageIntoTheSameSectionWithoutWelcomeMessage() {
        #expect(store.numberOfSections == 0)
        #expect(display.insertRowsCallCount == 0)
        
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 2))
        let position = collection.add(message: message)
        presenter.presentAdd(message: message, at: position)
        
        guard case .dateHeader = store[section: 0, row: 0] else { Issue.record() ; return }
        guard case .message = store[section: 0, row: 1] else { Issue.record() ; return }
        guard case .message = store[section: 0, row: 2] else { Issue.record() ; return }
        
        #expect(store.numberOfSections == 1)
        #expect(store.numberOfRows(inSection: 0) == 3)
        
        #expect(display.insertRowsCallCount == 1)
        #expect(display.insertRowsIndexPaths == [IndexPath(row: 2, section: 0)])
        
        #expect(display.deleteRowsCallCount == 0)
        #expect(display.reloadCallCount == 1, "Should be one because we called presentMessages")
    }
    
    @Test
    @MainActor
    mutating func insertMessageIntoTheSameSectionWithWelcomeMessage() {
        #expect(store.numberOfSections == 0)
        #expect(display.insertRowsCallCount == 0)
        
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 2))
        let position = collection.add(message: message)
        presenter.presentAdd(message: message, at: position)
        
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
        #expect(display.reloadCallCount == 1, "Should be one because we called presentMessages")
    }
    
    @Test
    @MainActor
    mutating func insertMessageIntoTheNewSectionWithoutWelcomeMessage() {
        #expect(store.numberOfSections == 0)
        #expect(display.insertRowsCallCount == 0)
        
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 86401))
        let position = collection.add(message: message)
        presenter.presentAdd(message: message, at: position)
        
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
        #expect(display.reloadCallCount == 1, "Should be one because we called presentMessages")
    }
    
    @Test
    @MainActor
    mutating func insertMessageIntoTheNewSectionWithWelcomeMessage() {
        #expect(store.numberOfSections == 0)
        #expect(display.insertRowsCallCount == 0)
        
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        presenter.presentMessages()
        display.RESET()
        
        let message = Message.makeTestData(time: Date(timeIntSince1970: 86401))
        let position = collection.add(message: message)
        presenter.presentAdd(message: message, at: position)
        
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
        #expect(display.reloadCallCount == 0)
    }
    
    @Test
    @MainActor
    mutating func test_ShouldBeCorrectlyConfigured_WhenStartingWithAMessageCollection() {
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
        self.presenter.set(sections: self.collection.sections)
        self.presenter.presentMessages()
        
        #expect(presenter.welcomeMessage == Self.welcomeMessage)
        #expect(presenter.stickyMessage == Self.stickyMessage)
        #expect(display.reloadCallCount == 1)
    
        guard case .info = store[section: 0, row: 0] else { Issue.record("First message should be the welcome message.") ; return }
        guard case .dateHeader = store[section: 1, row: 0] else { Issue.record("Second message should be the date header.") ; return }
        guard case .message(firstMessage) = store[section: 1, row: 1] else { Issue.record("Third message should be the first user message.") ; return }
        guard case .message(secondMessage) = store[section: 1, row: 2] else { Issue.record("Fourth message should be the second user message.") ; return }
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
