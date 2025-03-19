import Foundation
import Testing
@testable import Parley

@Suite("Messages Manager Tests")
struct MessagesManagerTests {

    struct MessagesManagerTestsError: Error {
        let message: String
    }

    private let MESSAGE_WELCOME_TEXT = "Welcome message"
    private let MESSAGE_STICKY_TEXT = "Sticky message"

    private let messagesManager: MessagesManager
    private let messageDataSource: ParleyMessageDataSource
    private let keyValueDataSource: ParleyKeyValueDataSource
    
    init() {
        messageDataSource = ParleyMessageDataSourceMock()
        keyValueDataSource = ParleyInMemoryKeyValueDataSource()
        messagesManager = MessagesManager(messageDataSource: messageDataSource, keyValueDataSource: keyValueDataSource)
    }

    @Test
    func testMessagesManager_ShouldBeEmpty_WhenCreated() async {
        #expect(await messagesManager.messages.isEmpty)
        #expect(await messagesManager.welcomeMessage == nil)
        #expect(await messagesManager.stickyMessage == nil)
        #expect(await messagesManager.paging == nil)
        #expect(await messagesManager.lastSentMessage == nil)
        #expect(await messagesManager.pendingMessages.isEmpty)
        #expect(await messagesManager.getOldestMessage() == nil)
    }

    @Test
    func testMessageManager_ShouldBeCorrectlyConfigured_WhenStartingWithAMessageCollection() async {
        let firstMessage = createUserMessage("Hello!")
        let secondMessage = createUserMessage("How are you?")
        let collection = MessageCollection(
            messages: [firstMessage, secondMessage],
            agent: nil,
            paging: MessageCollection.Paging(before: "", after: "After"),
            stickyMessage: MESSAGE_STICKY_TEXT,
            welcomeMessage: MESSAGE_WELCOME_TEXT
        )
        await messagesManager.handle(collection, .all)

        #expect(await messagesManager.welcomeMessage == MESSAGE_WELCOME_TEXT)
        #expect(await messagesManager.stickyMessage == MESSAGE_STICKY_TEXT)
        #expect(await messagesManager.messages[0] == firstMessage, "First message should be the first user message.")
        #expect(await messagesManager.messages[1] == secondMessage, "Second message should be the second user message.")
    }

    @Test
    func testWelcomeMessage_ShouldBeSet_WhenSettingTheWelcomeMessage() async {
        await setWelcomeMessage()
        await messagesManager.loadCachedData()
        #expect(await messagesManager.welcomeMessage == MESSAGE_WELCOME_TEXT)
        #expect(await messagesManager.messages.isEmpty, "Messages should remain empty")
    }

    @Test
    func testAddUserMessage_ShouldReturnTrue_WhenAddingInfoMessageAndFirstUserMessage() async {
        let didInsertMessage = await addInfoMessageAndFirstUserMessage()
        #expect(didInsertMessage)
    }

    @Test
    func testMessage_ShouldBeIgnored_WhenTryingToAddTheSameMessageTwice() async {
        let message = createUserMessage("Good morning")
        
        let didAddFirstMessage = await messagesManager.add(message)
        #expect(didAddFirstMessage)
        #expect(await messagesManager.messages.count == 1, "Should have added one message.")
        
        let didAddFirstMessageAgain = await messagesManager.add(message)
        #expect(didAddFirstMessageAgain == false)
        #expect(await messagesManager.messages.count == 1, "Array of messages should remain the same.")
    }

    @Test
    func testGetOldestMessage_ShouldReturnCorrectValueAtAllTimes_WhenInsertingMessages() async {
        #expect(await messagesManager.getOldestMessage() == nil)

        await setWelcomeMessage()
        await messagesManager.loadCachedData()
        #expect(await messagesManager.getOldestMessage() == nil)

        let firstMessage = createUserMessage("Good morning")
        _ = await messagesManager.add(firstMessage)
        guard await messagesManager.getOldestMessage() == firstMessage else { Issue.record() ; return }

        let secondMessage = createUserMessage("Second message")
        _ = await messagesManager.add(secondMessage)
        #expect(await messagesManager.getOldestMessage() == firstMessage)
    }

    @Test
    func testUpdateMessage_ShouldUpdateMessage_WhenGivenANewMessageObjectEqualUUID() async {
        let originalMessageText = "First original message"
        let originalMessage = Message.newTextMessage(originalMessageText, type: .user, status: .pending)

        _ = await messagesManager.add(originalMessage)
        // A date message gets added, last message is the user's message.
        #expect(await messagesManager.messages.last?.id == originalMessage.id)

        let updatedMessageText = "Updated message text"
        let updatedMessage = Message.makeTestData(
            id: originalMessage.id,
            time: Date(),
            message: updatedMessageText,
            type: .user,
            status: .pending
        )
        await messagesManager.update(updatedMessage)

        await #expect(messagesManager.messages.last!.message != originalMessageText)
        await #expect(messagesManager.messages.last!.message == updatedMessageText)
        await #expect(messagesManager.messages.last!.id == originalMessage.id)
    }
}

extension MessagesManagerTests {

    @discardableResult
    private func addInfoMessageAndFirstUserMessage() async -> Bool {
        await setWelcomeMessage()
        await messagesManager.loadCachedData()

        let firstMessage = createUserMessage("Good morning")
        return await messagesManager.add(firstMessage)
    }

    private func setWelcomeMessage() async {
        await keyValueDataSource.set(MESSAGE_WELCOME_TEXT, forKey: kParleyCacheKeyMessageInfo)
    }

    private func createUserMessage(_ message: String, date: Date = Date()) -> Message {
        var message = Message.newTextMessage(message, type: .user, status: .pending)
        message.time = date
        return message
    }

    private func getYesterdayDate() throws -> Date {
        let today = Date()
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else {
            throw MessagesManagerTestsError(message: "Failed to create a new date from yesterday.")
        }
        return yesterday
    }
}
