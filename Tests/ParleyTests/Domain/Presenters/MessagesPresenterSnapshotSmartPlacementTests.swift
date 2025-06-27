import Foundation
import Testing
@testable import Parley

@Suite("Messages Presenter Snapshot Tests – Smart welcome placement")
struct MessagesPresenterSnapshotSmartPlacementTests {

    // MARK: - Aliases & constants
    typealias Snapshot = MessagesPresenter.Snapshot
    static let welcomeMessage: String = "Welcome message"
    let calendar: Calendar = .autoupdatingCurrent

    // MARK: - Helpers
    private func startOfToday() -> Date { calendar.startOfDay(for: Date()) }
    private func startOfYesterday() -> Date {
        calendar.startOfDay(for: calendar.date(byAdding: .day, value: -1, to: Date())!)
    }

    @Test
    func setWelcomeMessage_WhenConversationIsEmpty_ShouldInsertInfoSectionAtTop() {
        var snapshot = Snapshot(
            welcomeMessage: nil,
            intelligentWelcomePositioning: true
        )

        let change = snapshot.set(welcomeMessage: Self.welcomeMessage)!

        #expect(
            change == Snapshot.SnapshotChange(
                indexPaths: [IndexPath(row: 0, section: 0)],
                kind: .added
            )
        )
        #expect(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].sectionKind == .info)
    }

    @Test
    func setWelcomeMessage_WithTodayMessages_ShouldBeInsertedAsFirstRowInTodaySection() throws {
        var snapshot = Snapshot(
            welcomeMessage: nil,
            intelligentWelcomePositioning: true
        )

        let messageToday1 = Message.makeTestData(
            time: Date(timeIntervalSinceNow: -10),
            message: "Hi"
        )
        _ = snapshot.insert(message: messageToday1)

        let change = snapshot.set(welcomeMessage: Self.welcomeMessage)!

        #expect(
            change == Snapshot.SnapshotChange(
                indexPaths: [IndexPath(row: 0, section: 0)],
                kind: .added
            )
        )
        try #require(snapshot.sections.count == 1)
        guard case .messages(let date) = snapshot.sections[0].sectionKind,
              date == startOfToday()
        else { Issue.record(); return }

        // Order: [welcome-info, firstMessage]
        #expect(snapshot.sections[0].cells.count == 2)
        #expect(snapshot.sections[0].cells[0].kind == .info(Self.welcomeMessage))
        #expect(snapshot.sections[0].cells[1].kind == .message(messageToday1))
    }

    @Test
    func setWelcomeMessage_WithOnlyPastMessages_ShouldShowWelcomeMessageAtBottom() throws {
        var snapshot = Snapshot(
            welcomeMessage: nil,
            intelligentWelcomePositioning: true
        )

        let pastMessage = Message.makeTestData(
            time: startOfYesterday().addingTimeInterval(60),
            message: "Yesterday"
        )
        _ = snapshot.insert(message: pastMessage)

        let change = snapshot.set(welcomeMessage: Self.welcomeMessage)!

        #expect(
            change == Snapshot.SnapshotChange(
                indexPaths: [IndexPath(row: 0, section: 1)],
                kind: .added
            )
        )

        try #require(snapshot.sections.count == 2)
        guard case .messages(let date) = snapshot.sections[0].sectionKind,
              date == startOfYesterday()
        else { Issue.record() ; return }

        #expect(snapshot.sections[1].sectionKind == .info)
        #expect(snapshot.sections[1].cells[0].kind == .info(Self.welcomeMessage))
    }

    @Test
    func setWelcomeMessage_WithTypingIndicatorOnly_ShouldInsertAboveTypingIndicator() throws {
        var snapshot = Snapshot(
            welcomeMessage: nil,
            intelligentWelcomePositioning: true
        )

        _ = snapshot.set(agentTyping: true)

        let change = snapshot.set(welcomeMessage: Self.welcomeMessage)!

        #expect(
            change == Snapshot.SnapshotChange(
                indexPaths: [IndexPath(row: 0, section: 0)],
                kind: .added
            )
        )
        try #require(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].sectionKind == .typingIndicator)
        #expect(snapshot.sections[0].cells.count == 2)
        #expect(snapshot.sections[0].cells[0].kind == .info(Self.welcomeMessage))
        #expect(snapshot.sections[0].cells[1].kind == .typingIndicator)
    }

    @Test
    func insertMessage_AfterWelcomeInTodaySection_ShouldAppendBelowExistingMessages() throws {
        var snapshot = Snapshot(
            welcomeMessage: nil,
            intelligentWelcomePositioning: true
        )

        let first = Message.makeTestData(time: Date(), message: "First")
        _ = snapshot.insert(message: first)

        _ = snapshot.set(welcomeMessage: Self.welcomeMessage)

        let second = Message.makeTestData(
            time: Date(timeIntervalSinceNow: 5),
            message: "Second"
        )
        let change = snapshot.insert(message: second)!

        #expect(
            change == Snapshot.SnapshotChange(
                indexPaths: [IndexPath(row: 2, section: 0)],
                kind: .added
            )
        )
        try #require(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].cells.count == 3)
        #expect(snapshot.sections[0].cells[0].kind == .info(Self.welcomeMessage))
        #expect(snapshot.sections[0].cells[1].kind == .message(first))
        #expect(snapshot.sections[0].cells[2].kind == .message(second))
    }
}
