import Foundation
import Testing
@testable import Parley

@Suite("Messages Presenter Snapshot Tests")
struct MessagesPresentSnapshotTests {
    
    typealias Snapshot = MessagesPresenter.Snapshot
    
    static let welcomeMessage: String = "Welcome message"
    
    @Test
    func createSnapshot_ShouldBeEmpty() {
        let snapshot = Snapshot(welcomeMessage: nil)
        #expect(snapshot.cells.isEmpty)
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
        #expect(snapshot.sections == [.typingIndicator])
        #expect(snapshot.cells == [[.typingIndicator]])
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
        
        #expect(snapshot.sections == [.info, .typingIndicator])
        #expect(snapshot.cells == [[.info(Self.welcomeMessage)], [.typingIndicator]])
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
        #expect(snapshot.sections == [.info, .loading])
        #expect(snapshot.cells == [[.info(Self.welcomeMessage)], [.loading]])
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
        #expect(snapshot.sections == [.loading])
        #expect(snapshot.cells == [[.loading]])
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
    
    // MARK: Append message
    
    @Test(arguments: [Self.welcomeMessage, nil], [true, false])
    func appendMessage_ShouldFail_WhenThereIsNoMessageSection(welcomeMessage: String?, loading: Bool) {
        var snapshot = Snapshot(welcomeMessage: welcomeMessage)
        _ = snapshot.setLoading(loading)
        
        #expect(snapshot.sections.contains(.messages) == false)
        
        let message = Message.makeTestData(time: Date())
        let change = snapshot.append(message: message)
        
        #expect(change == nil)
    }
    
    @Test
    func appendMessage_ShouldAppendMessage_WhenMessageSectionExsists_WithoutMWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: nil)
        let firstMessageDate = Date(timeIntSince1970: 1)!
        let firstMessage = Message.makeTestData(time: firstMessageDate)
        _ = snapshot.append(section: [firstMessage], date: firstMessageDate)
        
        let secondMessageDate = Date(timeIntSince1970: 2)!
        let secondMessage = Message.makeTestData(time: secondMessageDate)
        let change = snapshot.append(message: secondMessage)
        
        #expect(
            change! == Snapshot.SnapshotChange(indexPaths: [
                IndexPath(row: 2, section: 0), // Appended Message
            ], kind: .added)
        )
        #expect(snapshot.sections == [.messages])
        #expect(snapshot.cells == [[
            .dateHeader(firstMessageDate),
            .message(firstMessage),
            .message(secondMessage)
        ]])
    }
    
    @Test
    func appendMessage_ShouldAppendMessage_WhenMessageSectionExsists_WithWelcomeMessage() throws {
        var snapshot = Snapshot(welcomeMessage: Self.welcomeMessage)
        let firstMessageDate = Date(timeIntSince1970: 1)!
        let firstMessage = Message.makeTestData(time: firstMessageDate)
        _ = snapshot.append(section: [firstMessage], date: firstMessageDate)
        
        let secondMessageDate = Date(timeIntSince1970: 2)!
        let secondMessage = Message.makeTestData(time: secondMessageDate)
        let change = snapshot.append(message: secondMessage)
        
        #expect(
            change! == Snapshot.SnapshotChange(indexPaths: [
                IndexPath(row: 2, section: 1), // Appended Message
            ], kind: .added)
        )
        #expect(snapshot.sections == [.info, .messages])
        #expect(snapshot.cells == [
            [
                .info(Self.welcomeMessage)
            ],
            [
                .dateHeader(firstMessageDate),
                .message(firstMessage),
                .message(secondMessage)
        ]])
    }
}

private extension MessagesPresentSnapshotTests {
    
    func expectSnapshotContainsOnlyWelcomeMessage(_ snapshot: Snapshot) {
        #expect(snapshot.sections == [.info])
        #expect(snapshot.cells == [[.info(Self.welcomeMessage)]])
    }
}
