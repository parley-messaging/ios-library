import Foundation
import Testing
@testable import Parley

@Suite("Messages Presenter Tests - Adaptive welcome posisition")
@ParleyDomainActor
struct MessagesPresenterSnapshotWithAdaptiveWelcomeTests {
    
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
            usesAdaptiveWelcomePosistioning: true
        )
        collection = ParleyChronologicalMessageCollection(calendar: .current)
        
        await #expect(display.performBatchUpdatesCallCount == 0)
        
        await #expect(display.reloadCallCount == 0)
        
        await #expect(display.displayStickyMessageCallCount == 0)
        await #expect(display.displayHideStickyMessageCallCount == 0)
        
        await #expect(display.hasInteractedWithDisplay == false)
    }
    
    @Test
    mutating func presenter_ShouldDisplayWelcome_WhenCahtIsEmpty() async {
        // Setup
        presenter.set(welcomeMessage: Self.welcomeMessage)

        // When
        await presenter.presentMessages()

        // Then
        guard case .info(nil) = await store[section: 0] else { Issue.record() ; return }
    }
    
    @Test
    mutating func presenter_ShouldDisplayWelcome_WhenCahtIsEmpty_alt() async {
        // Setup
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)

        // When
        await presenter.presentMessages()

        // Then
        guard case .info(nil) = await store[section: 0] else { Issue.record() ; return }
    }
    
    @Test
    mutating func presenter_ShouldDisplayWelcomeMessageAtBottom_WhenNoMessagesWereSentToday() async {
        // Setup
        _ = collection.add(message: .makeTestData(time: Date(timeIntSince1970: 1)))
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        
        // When
        await presenter.presentMessages()
        
        // Then
        guard case .messages = await store[section: 0] else { Issue.record() ; return }
        guard case .message = await store[section: 0, row: 0] else { Issue.record() ; return }
        
        guard case .info(nil) = await store[section: 1] else {
            Issue.record("Date should be nil because there is no message for today's date") ; return
        }
        await #expect(store[section: 1, row: 0] == .info(Self.welcomeMessage))
        
        await #expect(store.numberOfSections == 2)
        await #expect(store.numberOfRows(inSection: 0) == 1)
        await #expect(store.numberOfRows(inSection: 1) == 1)
        
        await #expect(display.reloadCallCount == 1)
    }
    
    @Test
    mutating func presenter_ShouldDisplayWelcomeMessageAtBottom_WhenNoMessagesWereSentToday_2_days_variant() async {
        // Setup
        let firstMessage = Message.makeTestData(time: Date(timeIntSince1970: 1))
        _ = collection.add(message: firstMessage)
        presenter.set(welcomeMessage: Self.welcomeMessage)
        presenter.set(sections: collection.sections)
        await presenter.presentMessages()
        
        let secondMessage = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 1))
        _ = collection.add(message: secondMessage)
        
        // When
        await presenter.presentAdd(message: secondMessage)
        
        // Then
        guard case .messages(startOfDay(firstMessage.time)) = await store[section: 0] else { Issue.record() ; return }
        guard case .message = await store[section: 0, row: 0] else { Issue.record() ; return }
        
        guard case .messages(startOfDay(secondMessage.time)) = await store[section: 1] else { Issue.record() ; return }
        guard case .message = await store[section: 1, row: 0] else { Issue.record() ; return }
        
        guard case .info(nil) = await store[section: 2] else {
            Issue.record("Date should be nil because there is no message for today's date") ; return
        }
        await #expect(store[section: 2, row: 0] == .info(Self.welcomeMessage))
        
        await #expect(store.numberOfSections == 3)
        await #expect(store.numberOfRows(inSection: 0) == 1)
        await #expect(store.numberOfRows(inSection: 1) == 1)
        await #expect(store.numberOfRows(inSection: 2) == 1)
        
        await #expect(display.reloadCallCount == 1)
    }
    
    func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
}
