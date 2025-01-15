import Foundation
import Testing
@testable import Parley

@Suite("Messages Presenter Snapshot Tests")
struct MessagesPresentSnapshotTests {
    
    typealias Snapshot = MessagesPresenter.Snapshot
    
    static let welcomeMessage: String = "Welcome message"
    let calander: Calendar = .autoupdatingCurrent
    static let dayInSeconds: TimeInterval = 86_400
    
    @Test
    func createSnapshot_ShouldBeEmpty() {
        let snapshot = Snapshot(welcomeMessage: nil)
        #expect(snapshot.sections.isEmpty)
        #expect(snapshot.isEmpty)
    }
    
    
    // MARK: Welcome message
    
    @Test
    func createSnapshotWithWelcomeMessage_ShouldCreateCorrectSectionsAndCells() {
        let snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    // MARK: Agent Typing
    
    @Test
    func setAgentTypingOnSnapshotWithoutWelcomeMessage_Should() {
        var snapshot = Snapshot(welcomeMessage: nil)
        let change = snapshot.set(agentTyping: true)!
        #expect(
            change == Snapshot.SnapshotChange(indexPaths: [
                IndexPath(row: 0, section: 0)
            ], kind: .added)
        )
        #expect(snapshot.sections.count == 1)
        #expect(snapshot.sections.first?.sectionKind == .typingIndicator)
    }
    
    @Test
    func setAgentTypingOnSnapshotWithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        let change = snapshot.set(agentTyping: true)!
        #expect(
            change == Snapshot.SnapshotChange(indexPaths: [
                IndexPath(row: 0, section: 1)
            ], kind: .added)
        )
        #expect(snapshot.sections.count == 2)
        #expect(snapshot.sections[0].sectionKind == .info)
        #expect(snapshot.sections[1].sectionKind == .typingIndicator)
    }
    
    @Test
    func removeAgentTypingOnSnapshotWithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.set(agentTyping: true)
        let change = snapshot.set(agentTyping: false)!
        #expect(
            change == Snapshot.SnapshotChange(indexPaths: [
                IndexPath(row: 0, section: 1)
            ], kind: .deleted)
        )
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    @Test
    func setAgentTypingToTheSameValue() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        let change = snapshot.set(agentTyping: false)
        #expect(change == nil)
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    // MARK: Set loading
    
    @Test
    func enableLoadingMessages_shouldInsertCell_WithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        let change = snapshot.setLoading(true)!
        #expect(change == Snapshot.SnapshotChange(indexPaths: [
            IndexPath(row: 0, section: 1)
        ], kind: .added))
        #expect(snapshot.sections.count == 2)
        #expect(snapshot.sections[0].sectionKind == .info)
        #expect(snapshot.sections[1].sectionKind == .loading)
    }
    
    @Test
    func enableLoadingMessages_shouldInsertCell_WithoutWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: nil)
        let change = snapshot.setLoading(true)!
        #expect(
            change == Snapshot.SnapshotChange(indexPaths: [
                IndexPath(row: 0, section: 0)
            ], kind: .added)
        )
        #expect(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].sectionKind == .loading)
    }
    
    @Test
    func enableLoadingMessages_WhenIsAlreadyLoading_ShouldReturnNoChange_WithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        let change = snapshot.setLoading(false)
        #expect(change == nil)
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    @Test
    func enableLoadingMessages_WhenIsAlreadyLoading_ShouldReturnNoChangeWithoutWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: nil)
        let change = snapshot.setLoading(false)
        #expect(change == nil)
        #expect(snapshot.isEmpty)
    }
    
    @Test
    func dissableLoadingMessages_shouldDeleteCell_WithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.setLoading(true)
        let change = snapshot.setLoading(false)!
        #expect(
            change == Snapshot.SnapshotChange(indexPaths: [
                IndexPath(row: 0, section: 1)
            ], kind: .deleted)
        )
        expectSnapshotContainsOnlyWelcomeMessage(snapshot)
    }
    
    @Test
    func dissableLoadingMessages_shouldDeleteCell_WithoutWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: nil)
        _ = snapshot.setLoading(true)
        let change = snapshot.setLoading(false)!
        #expect(
            change == Snapshot.SnapshotChange(indexPaths: [
                IndexPath(row: 0, section: 0)
            ], kind: .deleted)
        )
        #expect(snapshot.isEmpty)
    }
    
    // MARK: Insert message
    
    @Test
    func insertMessage_ShoulInsert_WhenSnapshotIsEmpty() {
        var snapshot = Snapshot(welcomeMessage: nil)
        let message = Message.makeTestData(time: Date())
        
        let change = snapshot.insert(message: message)
        
        #expect(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].cells.count == 2)
        guard case .dateHeader = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[0].cells[1].kind else { Issue.record() ; return }
        #expect(change == Snapshot.SnapshotChange(indexPaths: [
            IndexPath(row: 0, section: 0),
            IndexPath(row: 1, section: 0),
        ], kind: .added))
    }
    
    @Test
    func insertMessage_ShoulInsertAfterWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        let message = Message.makeTestData(time: Date())
        
        let change = snapshot.insert(message: message)
        
        #expect(snapshot.sections.count == 2)
        #expect(snapshot.sections[0].cells.count == 1)
        #expect(snapshot.sections[1].cells.count == 2)
        guard case .info = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .dateHeader = snapshot.sections[1].cells[0].kind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[1].cells[1].kind else { Issue.record() ; return }
        #expect(change == Snapshot.SnapshotChange(indexPaths: [
            IndexPath(row: 0, section: 1),
            IndexPath(row: 1, section: 1),
        ], kind: .added))
    }
    
    @Test
    func insertMessage_ShoulInsertAfterLoadingIndicator() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.setLoading(true)
        let message = Message.makeTestData(time: Date())
        
        let change = snapshot.insert(message: message)
        
        #expect(snapshot.sections.count == 3)
        #expect(snapshot.sections[0].cells.count == 1)
        #expect(snapshot.sections[1].cells.count == 1)
        #expect(snapshot.sections[2].cells.count == 2)
        guard case .info = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .loading = snapshot.sections[1].cells[0].kind else { Issue.record() ; return }
        guard case .dateHeader = snapshot.sections[2].cells[0].kind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[2].cells[1].kind else { Issue.record() ; return }
        #expect(change == Snapshot.SnapshotChange(indexPaths: [
            IndexPath(row: 0, section: 2),
            IndexPath(row: 1, section: 2),
        ], kind: .added))
    }
    
    @Test
    func insertMessage_ShoulInsertBeforeAgentTypingIndicator() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.setLoading(true)
        _ = snapshot.set(agentTyping: true)
        let message = Message.makeTestData(time: Date())
        
        let change = snapshot.insert(message: message)
        
        #expect(snapshot.sections.count == 4)
        #expect(snapshot.sections[0].cells.count == 1)
        #expect(snapshot.sections[1].cells.count == 1)
        #expect(snapshot.sections[2].cells.count == 2)
        #expect(snapshot.sections[3].cells.count == 1)
        guard case .info = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .loading = snapshot.sections[1].cells[0].kind else { Issue.record() ; return }
        guard case .dateHeader = snapshot.sections[2].cells[0].kind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[2].cells[1].kind else { Issue.record() ; return }
        guard case .typingIndicator = snapshot.sections[3].cells[0].kind else { Issue.record() ; return }
        #expect(change == Snapshot.SnapshotChange(indexPaths: [
            IndexPath(row: 0, section: 2),
            IndexPath(row: 1, section: 2),
        ], kind: .added))
    }
    
    @Test
    func insertMessage_ShoulInsert_WhenSnapshotContainsWelcomeMessageAndLoadingIndicator() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        _ = snapshot.setLoading(true)
        let message = Message.makeTestData(time: Date())
        
        let change = snapshot.insert(message: message)
        
        #expect(snapshot.sections.count == 3)
        #expect(snapshot.sections[0].cells.count == 1)
        #expect(snapshot.sections[1].cells.count == 1)
        #expect(snapshot.sections[2].cells.count == 2)
        guard case .info = snapshot.sections[0].cells[0].kind else { Issue.record() ; return }
        guard case .loading = snapshot.sections[1].cells[0].kind else { Issue.record() ; return }
        guard case .dateHeader = snapshot.sections[2].cells[0].kind else { Issue.record() ; return }
        guard case .message(message) = snapshot.sections[2].cells[1].kind else { Issue.record() ; return }
        #expect(change == Snapshot.SnapshotChange(indexPaths: [
            IndexPath(row: 0, section: 2),
            IndexPath(row: 1, section: 2),
        ], kind: .added))
    }
}

private extension MessagesPresentSnapshotTests {
    
    func expectSnapshotContainsOnlyWelcomeMessage(_ snapshot: Snapshot) {
        #expect(snapshot.sections.count == 1)
        #expect(snapshot.sections[0].sectionKind == .info)
    }
    
    func startOfDay(_ date: Date = Date()) -> Date {
        calander.startOfDay(for: date)
    }
}
