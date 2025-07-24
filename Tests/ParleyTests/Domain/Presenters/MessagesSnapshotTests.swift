import Foundation
import Testing
@testable import Parley

@Suite("Messages Snapshot Tests - Regular tests")
struct MessagesSnapshotTests {
    
    typealias Snapshot = MessagesSnapshot
    
    static let welcomeMessage: String = "Welcome message"
    let calander: Calendar = .autoupdatingCurrent
    
    @Test
    func createSnapshot_ShouldBeEmpty() {
        let snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
        #expect(snapshot.sections.isEmpty)
        #expect(snapshot.isEmpty)
    }
    
    
    // MARK: Welcome message
    
    @Test
    func createSnapshotWithWelcomeMessage_ShouldCreateCorrectSectionsAndCells() {
        let snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    // MARK: Agent Typing
    
    @Test
    func setAgentTypingOnSnapshotWithoutWelcomeMessage_Should() throws {
        var snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
        let change = snapshot.set(agentTyping: true)!
        
        try #require(change.sectionChanges.count == 1)
        try #require(change.rowChanges.count == 1)
        #expect(change[section: 0] == .insert)
        #expect(change[section: 0, row: 0] == .insert)
        
        try #require(snapshot.sections.count == 1)
        #expect(snapshot.sections.first?.sectionKind == .typingIndicator)
    }
    
    @Test
    func setAgentTypingOnSnapshotWithWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        let change = snapshot.set(agentTyping: true)!
        
        try #require(change.sectionChanges.count == 1)
        try #require(change.rowChanges.count == 1)
        #expect(change[section: 1] == .insert)
        #expect(change[section: 1, row: 0] == .insert)
        
        try #require(snapshot.sections.count == 2)
        #expect(snapshot.sections[0].sectionKind == .info(nil))
        #expect(snapshot.sections[1].sectionKind == .typingIndicator)
    }
    
    @Test
    func removeAgentTypingOnSnapshotWithWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        _ = snapshot.set(agentTyping: true)
        let change = snapshot.set(agentTyping: false)!
        
        try #require(change.sectionChanges.count == 1)
        try #require(change.rowChanges.isEmpty)
        #expect(change[section: 1] == .delete)
        
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    @Test
    func setAgentTypingToTheSameValue() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        let change = snapshot.set(agentTyping: false)
        #expect(change == nil)
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    // MARK: Set loading
    
    @Test
    func enableLoadingMessages_shouldInsertCell_WithWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        guard let change = snapshot.setLoading(true) else { Issue.record() ; return }
        
        try #require(change.sectionChanges.count == 1)
        try #require(change.sectionChanges.count == 1)
        #expect(change[section: 1] == .insert)
        #expect(change[section: 1, row: 0] == .insert)
        
        #expect(snapshot.sections.count == 2)
        #expect(snapshot.sections[0].sectionKind == .info(nil))
        #expect(snapshot.sections[1].sectionKind == .loading)
    }
    
    @Test
    func enableLoadingMessages_shouldInsertCell_WithoutWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
        guard let change = snapshot.setLoading(true) else { Issue.record() ; return }
        
        try #require(change.sectionChanges.count == 1)
        try #require(change.sectionChanges.count == 1)
        #expect(change[section: 0] == .insert)
        #expect(change[section: 0, row: 0] == .insert)
        
        #expect(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].sectionKind == .loading)
    }
    
    @Test
    func enableLoadingMessages_WhenIsAlreadyLoading_ShouldReturnNoChange_WithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        let change = snapshot.setLoading(false)
        #expect(change == nil)
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    @Test
    func enableLoadingMessages_WhenIsAlreadyLoading_ShouldReturnNoChangeWithoutWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
        let change = snapshot.setLoading(false)
        #expect(change == nil)
        #expect(snapshot.isEmpty)
    }
    
    @Test
    func dissableLoadingMessages_shouldDeleteCell_WithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        _ = snapshot.setLoading(true)
        guard let change = snapshot.setLoading(false) else { Issue.record() ; return }
        
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.isEmpty)
        #expect(change[section: 1] == .delete)
        
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    @Test
    func dissableLoadingMessages_shouldDeleteCell_WithoutWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
        _ = snapshot.setLoading(true)
        guard let change = snapshot.setLoading(false) else { Issue.record() ; return }
        
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.isEmpty)
        #expect(change[section: 0] == .delete)
        #expect(snapshot.isEmpty)
    }
    
    // MARK: Insert message
    
    @Test
    func insertMessage_ShouldInsert_WhenSnapshotIsEmpty() throws {
        var snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
        let message = Message.makeTestData(time: Date())
        
        guard let changes = snapshot.insert(message: message) else { Issue.record() ; return }
        try #require(changes.sectionChanges.count == 1)
        try #require(changes.rowChanges.count == 1)
        
        #expect(changes[section: 0] == .insert)
        #expect(changes[section: 0, row: 0] == .insert)
        
        #expect(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].cells.count == 1)
        guard case .messages = snapshot.sections[0].sectionKind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
    }
    
    @Test
    func insertMessage_ShoulInsertAfterWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        let message = Message.makeTestData(time: Date())
        
        guard let changes = snapshot.insert(message: message) else { Issue.record() ; return }
        try #require(changes.sectionChanges.count == 1)
        try #require(changes.rowChanges.count == 1)
        
        #expect(changes[section: 1] == .insert)
        #expect(changes[section: 1, row: 0] == .insert)
        
        #expect(snapshot.sections.count == 2)
        #expect(snapshot.sections[0].cells.count == 1)
        #expect(snapshot.sections[1].cells.count == 1)
        guard case .info = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .messages = snapshot.sections[1].sectionKind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[1].cells[0].kind else { Issue.record() ; return }
    }
    
    @Test
    func insertMessage_ShoulInsertAfterLoadingIndicator() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        _ = snapshot.setLoading(true)
        let message = Message.makeTestData(time: Date())
        
        guard let changes = snapshot.insert(message: message) else { Issue.record() ; return }
        try #require(changes.sectionChanges.count == 1)
        try #require(changes.rowChanges.count == 1)
        #expect(changes[section: 2] == .insert)
        #expect(changes[section: 2, row: 0] == .insert)
        
        #expect(snapshot.sections.count == 3)
        #expect(snapshot.sections[0].cells.count == 1)
        #expect(snapshot.sections[1].cells.count == 1)
        #expect(snapshot.sections[2].cells.count == 1)
        guard case .info = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .loading = snapshot.sections[1].cells[0].kind else { Issue.record() ; return }
        guard case .messages = snapshot.sections[2].sectionKind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[2].cells[0].kind else { Issue.record() ; return }
    }
    
    @Test
    func insertMessage_ShoulInsertBeforeAgentTypingIndicator() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        _ = snapshot.setLoading(true)
        _ = snapshot.set(agentTyping: true)
        let message = Message.makeTestData(time: Date())
        guard let changes = snapshot.insert(message: message) else { Issue.record() ; return }
        try #require(changes.sectionChanges.count == 1)
        try #require(changes.rowChanges.count == 1)
        #expect(changes[section: 2] == .insert)
        #expect(changes[section: 2, row: 0] == .insert)
        
        #expect(snapshot.sections.count == 4)
        #expect(snapshot.sections[0].cells.count == 1)
        #expect(snapshot.sections[1].cells.count == 1)
        #expect(snapshot.sections[2].cells.count == 1)
        #expect(snapshot.sections[3].cells.count == 1)
        guard case .info = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .loading = snapshot.sections[1].cells[0].kind else { Issue.record() ; return }
        guard case .messages = snapshot.sections[2].sectionKind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[2].cells[0].kind else { Issue.record() ; return }
        guard case .typingIndicator = snapshot.sections[3].cells[0].kind else { Issue.record() ; return }
    }
    
    @Test
    func insertMessage_ShoulInsert_WhenSnapshotContainsWelcomeMessageAndLoadingIndicator() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        _ = snapshot.setLoading(true)
        let message = Message.makeTestData(time: Date())
        
        guard let changes = snapshot.insert(message: message) else { Issue.record() ; return }
        try #require(changes.sectionChanges.count == 1)
        try #require(changes.rowChanges.count == 1)
        #expect(changes[section: 2] == .insert)
        #expect(changes[section: 2, row: 0] == .insert)
        
        #expect(snapshot.sections.count == 3)
        #expect(snapshot.sections[0].cells.count == 1)
        #expect(snapshot.sections[1].cells.count == 1)
        #expect(snapshot.sections[2].cells.count == 1)
        guard case .info = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .loading = snapshot.sections[1].cells[0].kind else { Issue.record() ; return }
        guard case .messages = snapshot.sections[2].sectionKind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[2].cells[0].kind else { Issue.record() ; return }
    }
    
    // MARK: Insert Section
    
    @Test
    func insertSection_ShouldInsert_WhenSnapshotIsEmpty() {
        var snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
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
        #expect(snapshot.sections[0].cells[1].kind == .message(message2))
    }

    @Test
    func insertSection_ShouldInsertCorrectly_WhenSnapshotContainsWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        let message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "First day")
        let message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hello")
        let section = [message1, message2]
        
        guard let change = snapshot.insertSection(messages: section) else { Issue.record() ; return }
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 1] == .insert)
        #expect(change[section: 1, row: 0] == .insert)
        #expect(change[section: 1, row: 1] == .insert)
        
        try #require(snapshot.sections.count == 2)
        #expect(snapshot.sections[0].sectionKind == .info(nil))
        guard case .messages = snapshot.sections[1].sectionKind else { Issue.record() ; return }
        
        let startOfDay = startOfDay(Date(daysSince1970: 0))
        #expect(snapshot.sections[1].date == startOfDay)
        try #require(snapshot.sections[1].cells.count == 2)
        #expect(snapshot.sections[1].cells[0].kind == .message(message1))
        #expect(snapshot.sections[1].cells[1].kind == .message(message2))
    }
    
    @Test
    func insertSection_ShouldInsertCorrectly_WhenSnapshotContainsWelcomeMessageAndAgentTyping() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        _ = snapshot.set(agentTyping: true)
        
        let message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "First day")
        let message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hello")
        let section = [message1, message2]
        
        guard let change = snapshot.insertSection(messages: section) else { Issue.record() ; return }
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 1] == .insert)
        #expect(change[section: 1, row: 0] == .insert)
        #expect(change[section: 1, row: 1] == .insert)
        
        try #require(snapshot.sections.count == 3)
        #expect(snapshot.sections[0].sectionKind == .info(nil))
        guard case .messages = snapshot.sections[1].sectionKind else { Issue.record() ; return }
        
        let startOfDay = startOfDay(Date(daysSince1970: 0))
        #expect(snapshot.sections[1].date == startOfDay)
        try #require(snapshot.sections[1].cells.count == 2)
        #expect(snapshot.sections[1].cells[0].kind == .message(message1))
        #expect(snapshot.sections[1].cells[1].kind == .message(message2))
        
        #expect(snapshot.sections[2].cells.count == 1)
        #expect(snapshot.sections[2].sectionKind == .typingIndicator)
    }
    
    @Test
    func insertSection_ShouldInsertBeforeOtherMessageSection_WhenSnapshotIsOtherwiseEmpty() throws {
        var snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
        
        let section2message1 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 5), message: "Second day")
        let section2message2 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 10), message: "Hello")
        _ = snapshot.insertSection(messages: [section2message1, section2message2])
        
        let section1message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "Frist day")
        let section1message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hi")
        
        guard let change = snapshot.insertSection(messages: [section1message1, section1message2]) else { Issue.record() ; return }
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
        #expect(snapshot.sections[0].cells[0].kind == .message(section1message1))
        #expect(snapshot.sections[0].cells[1].kind == .message(section1message2))
    }
    
    @Test
    func insertSection_ShouldInsertAfterOtherMessageSection_WhenSnapshotIsOtherwiseEmpty() throws {
        var snapshot = Snapshot(welcomeMessage: nil, adaptiveWelcomePositioning: false)
        
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
        
        let startOfDay = startOfDay(Date(daysSince1970: 1))
        #expect(snapshot.sections[1].date == startOfDay)
        try #require(snapshot.sections[1].cells.count == 2)
        #expect(snapshot.sections[1].cells[0].kind == .message(s2message1))
        #expect(snapshot.sections[1].cells[1].kind == .message(s2message2))
    }
 
    @Test
    func insertSection_ShouldInsertBeforeOtherMessageSection_WhenSnapshotHasWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        
        let s2message1 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 5), message: "Second day")
        let s2message2 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 10), message: "Hello")
        _ = snapshot.insertSection(messages: [s2message1, s2message2])
        
        let s1message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "Frist day")
        let s1message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hi")
        
        guard let change = snapshot.insertSection(messages:  [s1message1, s1message2]) else { Issue.record() ; return }
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 1] == .insert)
        #expect(change[section: 1, row: 0] == .insert)
        #expect(change[section: 1, row: 1] == .insert)
        
        try #require(snapshot.sections.count == 3)
        #expect(snapshot.sections[0].sectionKind == .info(nil))
        guard case .messages = snapshot.sections[1].sectionKind else { Issue.record() ; return }
        guard case .messages = snapshot.sections[2].sectionKind else { Issue.record() ; return }
        
        
        let startOfDay = calander.startOfDay(for: Date(daysSince1970: 0))
        #expect(snapshot.sections[1].date == startOfDay)
        try #require(snapshot.sections[1].cells.count == 2)
        #expect(snapshot.sections[1].cells[0].kind == .message(s1message1))
        #expect(snapshot.sections[1].cells[1].kind == .message(s1message2))
    }

    @Test
    func insertSection_ShouldInsertAfterOtherMessageSection_WhenSnapshotHasWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage, adaptiveWelcomePositioning: false)
        
        let s1message1 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 5), message: "First day")
        let s1message2 = Message.makeTestData(time: Date(daysSince1970: 0, offsetSeconds: 10), message: "Hello")
        _ = snapshot.insertSection(messages: [s1message1, s1message2])
        
        let s2message1 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 5), message: "Second day")
        let s2message2 = Message.makeTestData(time: Date(daysSince1970: 1, offsetSeconds: 10), message: "Hi")
        
        guard let change = snapshot.insertSection(messages:  [s2message1, s2message2]) else { Issue.record() ; return }
        #expect(change.sectionChanges.count == 1)
        #expect(change.rowChanges.count == 2)
        #expect(change[section: 2] == .insert)
        #expect(change[section: 2, row: 0] == .insert)
        #expect(change[section: 2, row: 1] == .insert)
        
        try #require(snapshot.sections.count == 3)
        #expect(snapshot.sections[0].sectionKind == .info(nil))
        guard case .messages = snapshot.sections[1].sectionKind else { Issue.record() ; return }
        guard case .messages = snapshot.sections[2].sectionKind else { Issue.record() ; return }
        
        let startOfDay = calander.startOfDay(for: Date(daysSince1970: 1))
        #expect(snapshot.sections[2].date == startOfDay)
        try #require(snapshot.sections[2].cells.count == 2)
        #expect(snapshot.sections[2].cells[0].kind == .message(s2message1))
        #expect(snapshot.sections[2].cells[1].kind == .message(s2message2))
    }
}

private extension MessagesSnapshotTests {
    
    func expectSnapshotContainsOnlyWelcomeMessage(_ snapshot: Snapshot) {
        #expect(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].sectionKind == .info(nil))
    }
    
    func startOfDay(_ date: Date = Date()) -> Date {
        calander.startOfDay(for: date)
    }
}
