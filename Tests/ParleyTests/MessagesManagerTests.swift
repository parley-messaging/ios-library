import XCTest
@testable import Parley

final class MessagesManagerTests: XCTestCase {

    struct MessagesManagerTestsError: Error {
        let message: String
    }

    private let MESSAGE_WELCOME_TEXT = "Welcome message"
    private let MESSAGE_STICKY_TEXT = "Sticky message"

    private var messagesManager: MessagesManager!
    private var messageDataSource: ParleyMessageDataSource!
    private var keyValueDataSource: ParleyKeyValueDataSource!

    override func setUp() {
        messageDataSource = ParleyMessageDataSourceMock()
        keyValueDataSource = ParleyInMemoryKeyValueDataSource()
        messagesManager = MessagesManager(messageDataSource: messageDataSource, keyValueDataSource: keyValueDataSource)
    }

    func testMessagesManager_ShouldBeEmpty_WhenCreated() {
        XCTAssertTrue(messagesManager.messages.isEmpty)
        XCTAssertNil(messagesManager.welcomeMessage)
        XCTAssertNil(messagesManager.stickyMessage)
        XCTAssertNil(messagesManager.paging)
        XCTAssertNil(messagesManager.lastSentMessage)
        XCTAssertTrue(messagesManager.pendingMessages.isEmpty)
        XCTAssertNil(messagesManager.getOldestMessage())
    }

    func testMessageManager_ShouldBeCorrectlyConfigured_WhenStartingWithAMessageCollection() {
        let firstMessage = createUserMessage("Hello!")
        let secondMessage = createUserMessage("How are you?")
        let collection = MessageCollection(
            messages: [firstMessage, secondMessage],
            agent: nil,
            paging: MessageCollection.Paging(before: "", after: "After"),
            stickyMessage: MESSAGE_STICKY_TEXT,
            welcomeMessage: MESSAGE_WELCOME_TEXT
        )
        messagesManager.handle(collection, .all)

        XCTAssertEqual(messagesManager.welcomeMessage, MESSAGE_WELCOME_TEXT)
        XCTAssertEqual(messagesManager.stickyMessage, MESSAGE_STICKY_TEXT)
        XCTAssertEqual(messagesManager.messages[0], firstMessage, "First message should be the first user message.")
        XCTAssertEqual(messagesManager.messages[1], secondMessage, "Second message should be the second user message.")
    }

    func testWelcomeMessage_ShouldBeSet_WhenSettingTheWelcomeMessage() {
        setWelcomeMessage()
        messagesManager.loadCachedData()
        XCTAssertEqual(messagesManager.welcomeMessage, MESSAGE_WELCOME_TEXT)
        XCTAssertTrue(messagesManager.messages.isEmpty, "Messages should remain empty")
    }

    func testAddUserMessage_ShouldReturnTrue_WhenAddingInfoMessageAndFirstUserMessage() {
        let didInsertMessage = addInfoMessageAndFirstUserMessage()
        XCTAssertTrue(didInsertMessage)
    }
    
    func testDateHeaders_ShouldNotShowConsecutiveDateHeaders_WhenThereAreNoMessagesBetweenDateHeaders() {
        setWelcomeMessage()
        
        let systemMessage = Message()
        systemMessage.type = .systemMessageAgent
        systemMessage.time = Date(timeIntSince1970: 1)
        
        _ = messagesManager.add(systemMessage)
        
        let now = Date()
        let todayMessageText = "Good morning!"
        let todayMessageDate = now
        let todayMessage = createUserMessage(todayMessageText, date: todayMessageDate)
        _ = messagesManager.add(todayMessage)
        
        XCTAssertEqual(messagesManager.messages[0].type, .date)
        XCTAssertEqual(messagesManager.messages[0].time, now)
        XCTAssertEqual(messagesManager.messages[1].type, .user)
    }
    
    func testDateHeaders_ShouldNotShowConsecutiveDateHeaders_WhenThereIsOnlyATypingMessageBetweenDateHeaders() {
        setWelcomeMessage()
        
        let systemMessage = Message()
        systemMessage.type = .systemMessageAgent
        systemMessage.time = Date(timeIntSince1970: 1)
        
        _ = messagesManager.add(systemMessage)
        
        let agentTypingMessage = Message()
        agentTypingMessage.type = .agentTyping
        _ = messagesManager.add(agentTypingMessage)
        
        let now = Date()
        let todayMessageText = "Good morning!"
        let todayMessageDate = now
        let todayMessage = createUserMessage(todayMessageText, date: todayMessageDate)
        _ = messagesManager.add(todayMessage)
        
        XCTAssertEqual(messagesManager.messages[0].type, .date)
        XCTAssertEqual(messagesManager.messages[0].time, now)
        XCTAssertEqual(messagesManager.messages[1].type, .user)
    }

    func testMessage_ShouldBeIgnored_WhenTryingToAddTheSameMessageTwice() {
        let message = createUserMessage("Good morning")
        
        let didAddFirstMessage = messagesManager.add(message)
        XCTAssertTrue(didAddFirstMessage)
        XCTAssertEqual(messagesManager.messages.count, 1, "Should have added one message.")
        
        let didAddFirstMessageAgain = messagesManager.add(message)
        XCTAssertFalse(didAddFirstMessageAgain)
        XCTAssertEqual(messagesManager.messages.count, 1, "Array of messages should remain the same.")
    }

    func testGetOldestMessage_ShouldReturnCorrectValueAtAllTimes_WhenInsertingMessages() {
        XCTAssertNil(messagesManager.getOldestMessage())

        setWelcomeMessage()
        messagesManager.loadCachedData()
        XCTAssertNil(messagesManager.getOldestMessage())

        let firstMessage = createUserMessage("Good morning")
        _ = messagesManager.add(firstMessage)
        XCTAssertEqual(firstMessage, messagesManager.getOldestMessage())

        let secondMessage = createUserMessage("Second message")
        _ = messagesManager.add(secondMessage)
        XCTAssertEqual(firstMessage, messagesManager.getOldestMessage())
    }

    func testUpdateMessage_ShouldUpdateMessage_WhenGivenANewMessageObjectEqualUUID() {
        let originalMessage = Message()
        originalMessage.type = .user
        originalMessage.uuid = UUID().uuidString
        let originalMessageText = "First original message"
        originalMessage.message = originalMessageText

        _ = messagesManager.add(originalMessage)
        // A date message gets added, last message is the user's message.
        XCTAssertEqual(messagesManager.messages.last?.uuid, originalMessage.uuid)

        let updatedMessage = Message()
        updatedMessage.type = .user
        updatedMessage.uuid = originalMessage.uuid
        let updatedMessageText = "Updated message text"
        updatedMessage.message = updatedMessageText
        messagesManager.update(updatedMessage)

        XCTAssertNotEqual(messagesManager.messages.last!.message, originalMessageText)
        XCTAssertEqual(messagesManager.messages.last!.message, updatedMessageText)
        XCTAssertEqual(messagesManager.messages.last!.uuid, originalMessage.uuid)
    }
}

extension MessagesManagerTests {

    @discardableResult
    private func addInfoMessageAndFirstUserMessage() -> Bool {
        setWelcomeMessage()
        messagesManager.loadCachedData()

        let firstMessage = createUserMessage("Good morning")
        return messagesManager.add(firstMessage)
    }

    private func setWelcomeMessage() {
        keyValueDataSource.set(MESSAGE_WELCOME_TEXT, forKey: kParleyCacheKeyMessageInfo)
    }

    private func createUserMessage(_ message: String, date: Date = Date()) -> Message {
        let userMessage = Message()
        userMessage.message = message
        userMessage.time = date
        userMessage.type = .user
        return userMessage
    }

    private func getYesterdayDate() throws -> Date {
        let today = Date()
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else {
            throw MessagesManagerTestsError(message: "Failed to create a new date from yesterday.")
        }
        return yesterday
    }
}
