import Foundation
import Testing
@testable import Parley

@Suite("Messages Presenter Tests")
struct MessagesPresenterTests {
    
    
    private let store: MessagesStore
    private let display: ParleyMessagesDisplaySpy
    private let presenter: MessagesPresenter
    
    init() {
        store = MessagesStore()
        display = ParleyMessagesDisplaySpy()
        presenter = MessagesPresenter(store: store, display: display)
    }
    
    @Test
    func presenterEmptyState() {
        #expect(presenter.isAgentTyping == false)
        #expect(presenter.welcomeMessage == nil)
        #expect(store.sections.isEmpty)
        #expect(store.cells.isEmpty)
    }
    
    @Test
    func setWelcomeMessage() {
        presenter.set(welcomeMessage: "Welcome")
        #expect(presenter.welcomeMessage != nil)
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
        presenter.present(stickyMessage: "Sticky message")
        #expect(display.displayStickyMessageCallCount == 1)
    }
    
    @Test
    func setEmptySectionsShouldEmptyStore() {
        let sections: [ParleyChronologicalMessageCollection.Section] = []
        presenter.set(sections: sections)
        #expect(store.cells.isEmpty)
        #expect(store.sections.isEmpty)
    }
    
    @Test(.disabled())
    func setEmptySectionWithWelcomeMessage() {
        let sections: [ParleyChronologicalMessageCollection.Section] = []
        presenter.set(welcomeMessage: "Welcome")
        presenter.set(sections: sections)
        guard case .info = store.cells[0][0] else { Issue.record() ; return }
        #expect(store.sections.count == 1)
        #expect(store.cells.count == 1)
        #expect(store.cells[0].count == 1)
    }
    
    @Test
    func setSectionsWithOneMessageShouldUpdateStore() {
        let sections: [ParleyChronologicalMessageCollection.Section] = [
            .init(date: Date(timeIntervalSince1970: 1), messages: [
                .makeTestData(id: 1, time: Date(timeIntervalSince1970: 2)),
                .makeTestData(id: 2, time: Date(timeIntervalSince1970: 3)),
            ]),
            .init(date: Date(), messages: [
                .makeTestData(id: 2, time: Date()),
                .makeTestData(id: 3, time: Date()),
            ])
        ]
    }
    
    @Test
    func setSectionsShouldUpdateStore() {
        let sections: [ParleyChronologicalMessageCollection.Section] = [
            .init(date: Date(timeIntervalSince1970: 1), messages: [
                .makeTestData(id: 1, time: Date(timeIntervalSince1970: 2)),
                .makeTestData(id: 2, time: Date(timeIntervalSince1970: 3)),
            ]),
            .init(date: Date(), messages: [
                .makeTestData(id: 2, time: Date()),
                .makeTestData(id: 3, time: Date()),
            ])
        ]
    }
}
