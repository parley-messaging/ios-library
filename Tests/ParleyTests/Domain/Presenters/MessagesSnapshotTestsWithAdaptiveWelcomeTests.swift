import Foundation
import Testing
@testable import Parley

@Suite("Messages Snapshot Tests - Adaptive Welcome posistion tests")
struct MessagesSnapshotTestsWithAdaptiveWelcomeTests {
    
    typealias Snapshot = MessagesSnapshot
    
    static let welcomeMessage: String = "Welcome message"
    private let calendar: Calendar = .autoupdatingCurrent
    
    @Test
    func createSnapshot_ShouldBeEmpty() {
        let snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: true)
        #expect(snapshot.sections.isEmpty)
        #expect(snapshot.isEmpty)
    }
    
    @Test
    func createSnapshotWithWelcomeMessage_ShouldBeTheOnlyElement() async throws {
        let snapshot = createSnapshot(welcomeMessage: true)
        #expect(snapshot[section: 0] == .info(nil))
        #expect(snapshot.sections.count == 1)
    }
    
    @Test
    func createEmptySnapshot_ThenAddWelcomeMessage_ShoudResultInTheCorrectChange() async throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        guard let changes = snapshot.set(welcomeMessage: Self.welcomeMessage) else { Issue.record() ; return }
        try #require(changes.rowChanges.count == 1)
        try #require(changes.sectionChanges.count == 1)
        #expect(changes[section: 0] == .insert)
        #expect(changes[section: 0, row: 0] == .insert)
        #expect(snapshot.sections.count == 1)
        #expect(snapshot[section: 0] == .info(nil))
    }
    
    @Test
    func createSnapshot_ThenStartTypingAndAddWelcomeMessage_ShoudResultInTheCorrectChange() async throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        _ = snapshot.set(agentTyping: true)
        
        guard let changes = snapshot.set(welcomeMessage: Self.welcomeMessage) else { Issue.record() ; return }
        try #require(changes.rowChanges.count == 1)
        try #require(changes.sectionChanges.count == 1)
        #expect(changes[section: 0] == .insert)
        #expect(changes[section: 0, row: 0] == .insert)

        #expect(snapshot.sections.count == 2)
        #expect(snapshot[section: 0] == .info(nil))
        #expect(snapshot[section: 1] == .typingIndicator)
    }
    
    @Test
    func createSnapshot_AddWelcomeMessageThenStartTypingAnd_ShoudResultInTheCorrectChange() async throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        _ = snapshot.set(welcomeMessage: Self.welcomeMessage)
        
        guard let change = snapshot.set(agentTyping: true) else { Issue.record() ; return }
        
        #expect(change[section: 1] == .insert)
        #expect(change[section: 1, row: 0] == .insert)
        #expect(snapshot.sections.count == 2)
        #expect(snapshot[section: 0] == .info(nil))
        #expect(snapshot[section: 1] == .typingIndicator)
    }
    
    /// - Create snapshot
    /// - Set welcome message
    /// - Insert message from today
    ///
    /// This should reload the info section (0) because it now has a date header, and add a new section (1) for the messages without a date header.
    @Test
    func createSnapshot_SetWelcomeMessageThenInsertTodayMessage() async throws {
        var snapshot = createSnapshot(welcomeMessage: true)
        
        let messageDate = Date()
        guard let change = snapshot.insert(message: .makeTestData(time: messageDate)) else { Issue.record() ; return }
        
        try #require(change.sectionChanges.count == 2)
        try #require(change.rowChanges.count == 1)
        #expect(change[section: 0] == .reload)
        #expect(change[section: 1] == .insert)
        #expect(change[section: 1, row: 0] == .insert)
        
        try #require(snapshot.sections.count == 2)
        #expect(snapshot[section: 0] == .info(startOfDay(messageDate)))
        #expect(snapshot[section: 1] == .messages(nil))
    }
    
    /// - Create snapshot
    /// - Set welcome message
    /// - Insert message from *not* today
    ///
    /// This should insert the message section at index 0, so that the message seaction appears before the info section
    @Test
    func createSnapshot_SetWelcomeMessageThenInsertMessage() async throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        
        _ = snapshot.set(welcomeMessage: Self.welcomeMessage)
        
        let messageDate = Date(daysSince1970: 1)
        guard let changes = snapshot.insert(message: .makeTestData(time: messageDate)) else { Issue.record() ; return }
        #expect(changes.isEmpty == false, "Change should not be empty")
        
        try #require(changes.sectionChanges.count == 1)
        try #require(changes.rowChanges.count == 1)
        #expect(changes[section: 0] == .insert)
        #expect(changes[section: 0, row: 0] == .insert)
        
        try #require(snapshot.sections.count == 2)
        #expect(snapshot[section: 0] == .messages(calendar.startOfDay(for: messageDate)))
        #expect(snapshot[section: 1] == .info(nil))
    }
    
    /// - Create snapshot
    /// - Set welcome message
    /// - Set loading message
    /// - Insert message from *not* today
    ///
    /// This should insert the message section at index 1, so that the message seaction appears before the info section
    @Test
    func createSnapshot_SetWelcomeMessageSetLoadingMessageThenInsertMessage() async throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        
        _ = snapshot.set(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.setLoading(true)
        
        let messageDate = Date(daysSince1970: 1)
        guard let changes = snapshot.insert(message: .makeTestData(time: messageDate)) else { Issue.record() ; return }
        #expect(changes.isEmpty == false, "Change should not be empty")
        
        try #require(changes.sectionChanges.count == 1)
        try #require(changes.rowChanges.count == 1)
        #expect(changes[section: 1] == .insert)
        #expect(changes[section: 1, row: 0] == .insert)
        
        try #require(snapshot.sections.count == 3)
        #expect(snapshot[section: 0] == .loading)
        #expect(snapshot[section: 1] == .messages(calendar.startOfDay(for: messageDate)))
        #expect(snapshot[section: 2] == .info(nil))
    }
    
    /// - Create snapshot
    /// - Set welcome message
    /// - Set loading message
    /// - Set typing indicator
    /// - Insert message from **not**  today
    ///
    /// This should insert the message section at index 1, so that the message seaction appears before the info section
    @Test
    func createSnapshot_SetWelcomeMessageSetLoadingSetTypingIndicatorThenInsertMessage() async throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        
        _ = snapshot.set(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.setLoading(true)
        _ = snapshot.set(agentTyping: true)
        
        let messageDate = Date(daysSince1970: 1)
        guard let changes = snapshot.insert(message: .makeTestData(time: messageDate)) else { Issue.record() ; return }
        #expect(changes.isEmpty == false, "Change should not be empty")
        
        try #require(changes.sectionChanges.count == 1)
        try #require(changes.rowChanges.count == 1)
        #expect(changes[section: 1] == .insert)
        #expect(changes[section: 1, row: 0] == .insert)
        
        try #require(snapshot.sections.count == 4)
        #expect(snapshot[section: 0] == .loading)
        #expect(snapshot[section: 1] == .messages(calendar.startOfDay(for: messageDate)))
        #expect(snapshot[section: 2] == .info(nil))
        #expect(snapshot[section: 3] == .typingIndicator)
    }
    
    /// - Create snapshot
    /// - Set welcome message
    /// - Set loading message
    /// - Set typing indicator
    /// - Insert message from **today**
    ///
    /// This should reload the info section, becaue it now has a date header.
    /// And then insert the message section at index 2,so that the message seaction appears after the info section
    @Test
    func createSnapshot_SetWelcomeMessageSetLoadingSetTypingIndicatorThenInsertMessageFromToday() async throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        
        _ = snapshot.set(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.setLoading(true)
        _ = snapshot.set(agentTyping: true)
        
        let messageDate = Date()
        guard let changes = snapshot.insert(message: .makeTestData(time: messageDate)) else { Issue.record() ; return }
        #expect(changes.isEmpty == false, "Change should not be empty")
        
        try #require(changes.sectionChanges.count == 2)
        try #require(changes.rowChanges.count == 1)
        #expect(changes[section: 1] == .reload)
        #expect(changes[section: 2] == .insert)
        #expect(changes[section: 2, row: 0] == .insert)
        
        try #require(snapshot.sections.count == 4)
        #expect(snapshot[section: 0] == .loading)
        #expect(snapshot[section: 1] == .info(calendar.startOfDay(for: messageDate)))
        #expect(snapshot[section: 2] == .messages(nil))
        #expect(snapshot[section: 3] == .typingIndicator)
    }
    
    /// - Create snapshot
    /// - Set welcome message
    /// - Set loading message
    /// - Insert message from **today**
    ///
    /// This should reload the info section, becaue it now has a date header.
    /// And then insert the message section at index 2,so that the message seaction appears after the info section
    @Test
    func createSnapshot_SetWelcomeMessageSetLoadingThenInsertMessageFromToday() async throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        
        _ = snapshot.set(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.setLoading(true)
        
        let messageDate = Date()
        guard let changes = snapshot.insert(message: .makeTestData(time: messageDate)) else { Issue.record() ; return }
        #expect(changes.isEmpty == false, "Change should not be empty")
        
        try #require(changes.sectionChanges.count == 2)
        try #require(changes.rowChanges.count == 1)
        #expect(changes[section: 1] == .reload)
        #expect(changes[section: 2] == .insert)
        #expect(changes[section: 2, row: 0] == .insert)
        
        try #require(snapshot.sections.count == 3)
        #expect(snapshot[section: 0] == .loading)
        #expect(snapshot[section: 1] == .info(calendar.startOfDay(for: messageDate)))
        #expect(snapshot[section: 2] == .messages(nil))
    }
    
    // MARK: Insert Section
    
    @Test
    func insertSection_ShouldInsert_WhenSnapshotIsEmpty() {
        var snapshot = createSnapshot(welcomeMessage: false)
        let message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "First day")
        let message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hello")
        let section = [message1, message2]
        
        guard let change = snapshot.insertSection(messages: section) else { Issue.record() ; return }
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 0] == .insert)
        #expect(change[section: 0, row: 0] == .insert)
        #expect(change[section: 0, row: 1] == .insert)
        
        #expect(snapshot.sections.count == 1)
        
        let startOfDay = startOfDay(Date(daysSince1970: 0))
        #expect(snapshot.sections[0].date == startOfDay)
        #expect(snapshot.sections[0].cells.count == 2)
        #expect(snapshot.sections[0].cells[0].kind == .message(message1))
        #expect(snapshot[section: 0, row: 0] == .message(message1))
        #expect(snapshot[section: 0, row: 1] == .message(message2))
    }

    @Test
    func insertSectionFromNotToday_ShouldInsertBeforeInfoSection_WhenSnapshotContainsWelcomeMessage() throws {
        // Given
        var snapshot = createSnapshot(welcomeMessage: true)
        let message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "First day")
        let message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hello")
        let section = [message1, message2]
        
        // When
        guard let change = snapshot.insertSection(messages: section) else { Issue.record() ; return }
        
        // Then
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 0] == .insert)
        #expect(change[section: 0, row: 0] == .insert)
        #expect(change[section: 0, row: 1] == .insert)
        
        let startOfDay = startOfDay(Date(daysSince1970: 0))
        try #require(snapshot.sections.count == 2)
        
        try #require(snapshot.sections[0].cells.count == 2)
        #expect(snapshot[section: 0] == .messages(startOfDay))
        #expect(snapshot[section: 0, row: 0] == .message(message1))
        #expect(snapshot[section: 0, row: 1] == .message(message2))
        
        try #require(snapshot.sections[1].cells.count == 1)
        #expect(snapshot[section: 1] == .info(nil))
    }
    
    @Test
    func insertSectionFromNotToday_ShouldInsertCorrectly_WhenSnapshotContainsWelcomeMessageAndAgentTyping() throws {
        // Given
        var snapshot = createSnapshot(welcomeMessage: true)
        _ = snapshot.set(agentTyping: true)
        let message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "First day")
        let message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hello")
        let section = [message1, message2]
        
        // When
        guard let change = snapshot.insertSection(messages: section) else { Issue.record() ; return }
        
        // Then
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 0] == .insert)
        #expect(change[section: 0, row: 0] == .insert)
        #expect(change[section: 0, row: 1] == .insert)
        
        let startOfDay = startOfDay(Date(daysSince1970: 0))
        try #require(snapshot.sections.count == 3)
        
        try #require(snapshot.sections[0].cells.count == 2)
        #expect(snapshot[section: 0] == .messages(startOfDay))
        #expect(snapshot[section: 0, row: 0] == .message(message1))
        #expect(snapshot[section: 0, row: 1] == .message(message2))
        
        try #require(snapshot.sections[1].cells.count == 1)
        #expect(snapshot[section: 1] == .info(nil))
        #expect(snapshot[section: 1, row: 0] == .info(Self.welcomeMessage))
        
        try #require(snapshot.sections[2].cells.count == 1)
        #expect(snapshot[section: 2] == .typingIndicator)
        #expect(snapshot[section: 2, row: 0] == .typingIndicator)
    }
    
    @Test
    func insertSection_ShouldInsertBeforeOtherMessageSection_WhenSnapshotIsOtherwiseEmpty() throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        
        let section2message1 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 5), message: "Second day")
        let section2message2 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 10), message: "Hello")
        _ = snapshot.insertSection(messages: [section2message1, section2message2])
        
        let section1message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "Frist day")
        let section1message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hi")
        
        guard let change = snapshot.insertSection(messages: [section1message1, section1message2]) else { Issue.record() ; return }
        print(change)
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 0] == .insert)
        #expect(change[section: 0, row: 0] == .insert)
        #expect(change[section: 0, row: 1] == .insert)
        
        try #require(snapshot.sections.count == 2)
        #expect(snapshot.sections.allSatisfy({
            guard case .messages = $0.sectionKind else { return false }
            return true
        }))
        
        let startOfDay = startOfDay(Date(daysSince1970: 0))
        #expect(snapshot.sections[0].date == startOfDay)
        try #require(snapshot.sections[0].cells.count == 2)
        #expect(snapshot[section: 0, row: 0] == .message(section1message1))
        #expect(snapshot[section: 0, row: 1] == .message(section1message2))
    }
    
    @Test
    func insertSection_ShouldInsertAfterOtherMessageSection_WhenSnapshotIsOtherwiseEmpty() throws {
        var snapshot = createSnapshot(welcomeMessage: false)
        
        let s1message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "First day")
        let s1message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hello")
        _ = snapshot.insertSection(messages: [s1message1, s1message2])
        
        let s2message1 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 5), message: "Second day")
        let s2message2 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 10), message: "Hi")
        
        guard let change = snapshot.insertSection(messages: [s2message1, s2message2]) else { Issue.record() ; return }
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 1] == .insert)
        #expect(change[section: 1, row: 0] == .insert)
        #expect(change[section: 1, row: 1] == .insert)
        
        try #require(snapshot.sections.count == 2)
        #expect(snapshot.sections.allSatisfy({
            guard case .messages = $0.sectionKind else { return false }
            return true
        }))
        
        try #require(snapshot.sections[0].cells.count == 2)
        #expect(snapshot[section: 0, row: 0] == .message(s1message1))
        #expect(snapshot[section: 0, row: 1] == .message(s1message2))
        
        try #require(snapshot.sections[1].cells.count == 2)
        #expect(snapshot[section: 1, row: 0] == .message(s2message1))
        #expect(snapshot[section: 1, row: 1] == .message(s2message2))
    }

    @Test
    func insertSection_ShouldInsertBeforeOtherMessageSection_WhenSnapshotHasWelcomeMessage() throws {
        var snapshot = createSnapshot(welcomeMessage: true)
        
        let s2message1 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 5), message: "Second day")
        let s2message2 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 10), message: "Hello")
        _ = snapshot.insertSection(messages: [s2message1, s2message2])
        
        let s1message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "Frist day")
        let s1message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hi")
        
        guard let change = snapshot.insertSection(messages:  [s1message1, s1message2]) else { Issue.record() ; return }
        print(change)
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 0] == .insert)
        #expect(change[section: 0, row: 0] == .insert)
        #expect(change[section: 0, row: 1] == .insert)
        
        try #require(snapshot.sections.count == 3)
        #expect(snapshot[section: 0] == .messages(startOfDay(s1message1.time)))
        #expect(snapshot[section: 1] == .messages(startOfDay(s2message1.time)))
        #expect(snapshot[section: 2] == .info(nil))
        
        try #require(snapshot.sections[0].cells.count == 2)
        #expect(snapshot[section: 0, row: 0] == .message(s1message1))
        #expect(snapshot[section: 0, row: 1] == .message(s1message2))
        
        try #require(snapshot.sections[1].cells.count == 2)
        #expect(snapshot[section: 1, row: 0] == .message(s2message1))
        #expect(snapshot[section: 1, row: 1] == .message(s2message2))
    }
}

extension MessagesSnapshotTestsWithAdaptiveWelcomeTests {
    
    func startOfDay(_ date: Date) -> Date {
        calendar.startOfDay(for: date)
    }
    
    func createSnapshot(welcomeMessage: Bool) -> Snapshot {
        Snapshot(
            welcomeMessage: welcomeMessage ? Self.welcomeMessage : nil,
            adaptiveWelcomePositioning: true
        )
    }
}
