import Foundation
import Testing
@testable import Parley

@Suite("Messages Presenter Snapshot Tests")
struct MessagesPresentSnapshotTests {
    
    typealias Snapshot = MessagesPresenter.Snapshot
    
    @Test
    func createEmptySnapshot() {
        let snapshot = Snapshot(welcomeMessage: nil)
        #expect(snapshot.cells.isEmpty)
        #expect(snapshot.sections.isEmpty)
    }
    
    
    // MARK: Welcome message
    
    @Test
    func createSnapshotWithWelcomeMessage() {
        let snapshot = Snapshot(welcomeMessage: "Welcome")
        #expect(snapshot.cells.count == 1)
        #expect(snapshot.sections.count == 1)
    }
    
    // MARK: Agent Typing
    
    @Test
    func setAgentTypingOnSnapshotWithoutWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: nil)
        let change = snapshot.set(agentTyping: true)
        #expect(change.indexPaths == [IndexPath(row: 0, section: 0)])
        #expect(change.kind == .added)
    }
    
    @Test
    func setAgentTypingOnSnapshotWithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        let change = snapshot.set(agentTyping: true)
        #expect(change.indexPaths == [IndexPath(row: 0, section: 1)])
        #expect(change.kind == .added)
    }
    
    @Test
    func removeAgentTypingOnSnapshotWithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        _ = snapshot.set(agentTyping: true)
        let change = snapshot.set(agentTyping: false)
        #expect(change.indexPaths == [IndexPath(row: 0, section: 1)])
        #expect(change.kind == .deleted)
    }
    
    @Test
    func setAgentTypingToTheSameValue() {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        let change = snapshot.set(agentTyping: false)
        #expect(change == .noChange)
    }
    
    // MARK: Set loading
    
    @Test
    func enableLoadingMessages_shouldInsertCell() {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        let change = snapshot.setLoading(true)
        #expect(change.kind == .added)
        guard case .info = snapshot.cells[0][0] else { Issue.record() ; return }
        guard case .loading = snapshot.cells[1][0] else { Issue.record() ; return }
    }
    
    @Test
    func enableLoadingMessages_WhenIsAlreadyLoading_ShouldReturnNoChange() {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        let change = snapshot.setLoading(false)
        #expect(change == .noChange)
    }
    
    @Test
    func dissableLoadingMessages_shouldDeleteCell() {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        _ = snapshot.setLoading(true)
        let change = snapshot.setLoading(false)
        #expect(change.kind == .deleted)
        guard case .info = snapshot.cells[0][0] else { Issue.record() ; return }
    }
    
    // MARK: Insert messages
    
    @Test
    func insertMessageToEmptySnapshot() {
        var snapshot = Snapshot(welcomeMessage: .none)
        let change = snapshot.insert(message: .makeTestData(time: Date()), section: 0, row: 0)
        #expect(change.indexPaths == [
            IndexPath(row: 0, section: 0), // Date header
            IndexPath(row: 1, section: 0), // Message
        ])
        #expect(change.kind == .added)
        guard case .dateHeader = snapshot.cells[0][0] else { Issue.record() ; return }
        guard case .message = snapshot.cells[0][1] else { Issue.record() ; return }
    }
    
    @Test
    func insertMessageToSnapshotWithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        let change = snapshot.insert(message: .makeTestData(time: Date()), section: 0, row: 0)
        #expect(change.indexPaths == [
            IndexPath(row: 0, section: 1),
            IndexPath(row: 1, section: 1),
        ])
        #expect(change.kind == .added)
        guard case .info = snapshot.cells[0][0] else { Issue.record() ; return }
        guard case .dateHeader = snapshot.cells[1][0] else { Issue.record() ; return }
        guard case .message = snapshot.cells[1][1] else { Issue.record() ; return }
    }
    
    @Test
    func insertTowMessagesSnapshotWithWelcomeMessage() {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        let change = snapshot.insert(message: .makeTestData(time: Date()), section: 0, row: 0)
        #expect(change.indexPaths == [
            IndexPath(row: 0, section: 1),
            IndexPath(row: 1, section: 1),
        ])
        #expect(change.kind == .added)
        guard case .info = snapshot.cells[0][0] else { Issue.record() ; return }
        guard case .dateHeader = snapshot.cells[1][0] else { Issue.record() ; return }
        guard case .message = snapshot.cells[1][1] else { Issue.record() ; return }
    }
    
    @Test("Insert one message in a new section", arguments: [true, false])
    func insertOneMessageInANewSectionWithWelcomeMessage(agentTyping: Bool) {
        var snapshot = Snapshot(welcomeMessage: "Welcome message")
        _ = snapshot.insert(message: .makeTestData(time: .init(timeIntSince1970: 1)), section: 0, row: 0)
        _ = snapshot.insert(message: .makeTestData(time: .init(timeIntSince1970: 2)), section: 0, row: 1)
        
        _ = snapshot.set(agentTyping: agentTyping)
        
        let change = snapshot.insert(message: .makeTestData(time: Date()), section: 1, row: 0)
        #expect(change.indexPaths == [
            IndexPath(row: 0, section: 2),
            IndexPath(row: 1, section: 2),
        ])
        #expect(change.kind == .added)
        guard case .info = snapshot.cells[0][0] else { Issue.record() ; return }
        guard case .dateHeader = snapshot.cells[1][0] else { Issue.record() ; return }
        guard case .message = snapshot.cells[1][1] else { Issue.record() ; return }
        guard case .message = snapshot.cells[1][2] else { Issue.record() ; return }
        guard case .dateHeader = snapshot.cells[2][0] else { Issue.record() ; return }
        guard case .message = snapshot.cells[2][1] else { Issue.record() ; return }
        
        if agentTyping {
            guard case .typingIndicator = snapshot.cells[3][0] else { Issue.record() ; return }
        } else {
            #expect(snapshot.cells.count == 3)
            #expect(snapshot.sections.count == 3)
        }
    }
}
