import XCTest
@testable import Parley

final internal class MessagesManagerTests: XCTestCase {
    
    internal let MESSAGE_WELCOME_TEXT = "Welcome message";
    internal let MESSAGE_STICKY_TEXT = "Sticky message";
    
    internal var messagesManager = MessagesManager()
    internal var dataSource = ParleyInMemoryDataSource()
    
    func setUp() {
        messagesManager = MessagesManager()
        dataSource = ParleyInMemoryDataSource()
        Parley.shared.dataSource = dataSource
     }
    
    func testMessagesManagerIsEmptyOnCreation() {
        XCTAssertTrue(messagesManager.messages.isEmpty)
        XCTAssertNil(messagesManager.welcomeMessage)
        XCTAssertNil(messagesManager.stickyMessage)
        XCTAssertNil(messagesManager.paging)
        XCTAssertNil(messagesManager.lastSentMessage)
        XCTAssertTrue(messagesManager.pendingMessages.isEmpty)
        XCTAssertNil(messagesManager.getOldestMessage())
    }
    
    func testWelcomeMessageIsReadAndAddedToMessages() {
        setWelcomeMessage()
        messagesManager.loadCachedData()
        
        XCTAssertEqual(messagesManager.welcomeMessage, MESSAGE_WELCOME_TEXT)
        
        guard let firstMessage = messagesManager.messages.first else {
            XCTFail("Welcome message should have been added to the array.") ; return
        }
        XCTAssertEqual(firstMessage.message, MESSAGE_WELCOME_TEXT, "First message should be the welcome message.")
        
        XCTAssertEqual(messagesManager.messages.count, 1, "Welcome message should be the only message in the messages array.")
    }
    
    func testAddUserMessageReturnCorrectIndexPath() {
        let firstMessageInsertionIndexPaths = addInfoMessageAndFirstUserMessage()
        
        XCTAssertEqual(firstMessageInsertionIndexPaths[0].row, 1, "First index path should correspond to the second item in the table view.")
        XCTAssertEqual(firstMessageInsertionIndexPaths[0].section, 0, "Section should always to 0.")
        
        XCTAssertEqual(firstMessageInsertionIndexPaths[1].row, 2, "Second index path should correspond to the third item in the table view.")
        XCTAssertEqual(firstMessageInsertionIndexPaths[1].section, 0, "Section should always to 0.")
        
        XCTAssertEqual(firstMessageInsertionIndexPaths.count, 2)
    }
    
    func testFirstSentUserMessageAfterWelcomeMessage() {
        setWelcomeMessage()
        messagesManager.loadCachedData()
        
        let firstMessageText = "Good morning!"
        let currentDate = Date()
        let userMessage = createUserMessage(firstMessageText, date: currentDate)
        
        _ = messagesManager.add(userMessage)
        
        XCTAssertEqual(messagesManager.messages[0].message, MESSAGE_WELCOME_TEXT, "First message should be welcome message.")
        XCTAssertEqual(messagesManager.messages[1].type, .date, "Second message should be date header.")
        XCTAssertEqual(messagesManager.messages[1].message, currentDate.asDate(), "Second message should contain the date of the added message.")
        XCTAssertEqual(messagesManager.messages[2].message, firstMessageText, "Third message should be the added message.")
        XCTAssertEqual(messagesManager.messages[2].type, .user, "Added message should be from the user.")
        
        XCTAssertNil(messagesManager.lastSentMessage, "Message should not be considered as being sent.")
    }
    
    func testTwoMessagesOnDifferentDaysAreSeparatedByDateIndicators() {
        setWelcomeMessage()
        messagesManager.loadCachedData()
        
        guard let yesterdayDate = getYesterdayDate() else {
            XCTFail("Failed to create a new date from yesterday.") ; return
        }
        let yesterdayMessageText = "All my troubles seemed so far away"
        let yesterdayMessage = createUserMessage(yesterdayMessageText, date: yesterdayDate)
        _ = messagesManager.add(yesterdayMessage)
        
        let todayMessageText = "Good morning!"
        let todayMessageDate = Date()
        let todayMessage = createUserMessage(todayMessageText, date: todayMessageDate)
        _ = messagesManager.add(todayMessage)
        
        XCTAssertEqual(messagesManager.messages[0].message, MESSAGE_WELCOME_TEXT, "First message should be welcome message.")
        
        XCTAssertEqual(messagesManager.messages[1].type, .date, "Second message should be date header.")
        XCTAssertEqual(messagesManager.messages[1].message, yesterdayDate.asDate(), "Date indicator text should be the same as the formatted date.")
        
        XCTAssertEqual(messagesManager.messages[2].message, yesterdayMessageText, "Yesterday message should have the correct message text.")
        XCTAssertEqual(messagesManager.messages[2].type, .user, "Yesterday message should be from the user.")
        
        XCTAssertEqual(messagesManager.messages[3].type, .date, "Fourth message should be date header.")
        XCTAssertEqual(messagesManager.messages[3].message, todayMessageDate.asDate(), "Date indicator text should be the same as the formatted date.")

        XCTAssertEqual(messagesManager.messages[4].message, todayMessageText, "Today message should have the correct message text.")
        XCTAssertEqual(messagesManager.messages[4].type, .user, "Today message should be from the user.")
    }
    
    func testShouldIgnoreAddedTheSameMessageTwice() {
        let message = createUserMessage("Good morning")
        let firstInsertionIndexPaths = messagesManager.add(message)
        
        XCTAssertEqual(firstInsertionIndexPaths.count, 2, "There should be two IndexPath after inserting a new message. One for the date indicator and the other is for the new message.")
        XCTAssertEqual(messagesManager.messages.count, 2, "There should now be two one message in the messages array.")
        
        let secondInsertionIndexPaths = messagesManager.add(message)
        XCTAssertTrue(secondInsertionIndexPaths.isEmpty, "Array should be empty because it should not insert the same message twice.")
        XCTAssertEqual(messagesManager.messages.count, 2, "Array of messages should remain the same.")
    }
    
    func testAddingTypingIndicator() {
        addInfoMessageAndFirstUserMessage()
        
        let indexPaths = messagesManager.addTypingMessage()
        XCTAssertEqual(indexPaths.count, 1, "Adding Typing indicator should only add a single IndexPath.")
        XCTAssertEqual(indexPaths.count, 1, "Adding Typing indicator should only add a single IndexPath.")
        
        XCTAssertEqual(indexPaths[0].row, 3, "Typing message should be the forth index.")
        XCTAssertEqual(indexPaths[0].section, 0, "Typing message should be the forth index.")
        
        XCTAssertEqual(messagesManager.messages.last!.type, .agentTyping, "Last message should be of type agent typing.")
    }
    
    func testAddingTypingIndicatorTwiceShouldNotAddTwoTyingIndicators() {
        addInfoMessageAndFirstUserMessage()
        
        let indexPathsFirstTypingMessage = messagesManager.addTypingMessage()
        XCTAssertEqual(indexPathsFirstTypingMessage.count, 1)
        
        let indexPathsSecondTypingMessage = messagesManager.addTypingMessage()
        XCTAssertTrue(indexPathsSecondTypingMessage.isEmpty)
    }
    
    func testTryingToRemovingNonExistentTypingIndicator() {
        addInfoMessageAndFirstUserMessage()
        
        XCTAssertNotEqual(messagesManager.messages.last!.type, .agentTyping, "There shouldn't be a typing message present.")
        XCTAssertNil(messagesManager.removeTypingMessage(), "Trying to remove a typing message without there being one should result in nil being returned.")
    }
    
    func testAddingAndRemovingTyingIndicator() {
        addInfoMessageAndFirstUserMessage()
        
        _ = messagesManager.addTypingMessage()
        
        let removedTyingMessageIndexPaths = messagesManager.removeTypingMessage()
        
        XCTAssertNotEqual(messagesManager.messages.last!.type, .agentTyping, "Last message should not be a agent typing kind.")
        XCTAssertNotNil(removedTyingMessageIndexPaths, "Should not be nil because it should contain one IndexPath to remove.")
        XCTAssertEqual(removedTyingMessageIndexPaths!.count, 1, "Only one element should have been added.")
        XCTAssertEqual(removedTyingMessageIndexPaths![0].row, 3, "Should remove at row 3.")
        XCTAssertEqual(removedTyingMessageIndexPaths![0].section, 0, "Section index should always be 0.")
    }
    
    func testAddingMessageWhileAgentIsTying() {
        setWelcomeMessage()
        messagesManager.loadCachedData()
        let firstMessage = createUserMessage("Good morning")
        _ = messagesManager.add(firstMessage)
        _ = messagesManager.addTypingMessage()
        
        XCTAssertEqual(messagesManager.messages[3].type, .agentTyping, "Forth message should be the typing indicator.")
        XCTAssertEqual(messagesManager.messages.last, messagesManager.messages[3], "Tying indicator should be the last message.")
        
        let secondMessageText = "👀"
        let secondMessage = createUserMessage(secondMessageText)
        let indexPaths = messagesManager.add(secondMessage)
        XCTAssertEqual(indexPaths.count, 1, "Only one IndexPath should have been added.")
        
        XCTAssertEqual(messagesManager.messages[0].type, .info, "First message should be the info message.")
        XCTAssertEqual(messagesManager.messages[1].type, .date, "Second message should be the date indicator.")
        XCTAssertEqual(messagesManager.messages[2].type, .user, "Third message should be the first user message.")
        XCTAssertEqual(messagesManager.messages[3].type, .user, "Forth message should be the second message from the user.")
        XCTAssertEqual(indexPaths[0].row, 3, "first index path should insert at index 3.")
        XCTAssertEqual(messagesManager.messages[4].type, .agentTyping, "Fifth message should the typing indicator.")
        XCTAssertEqual(messagesManager.messages.last, messagesManager.messages[4], "Tying indicator should be the last message.")
    }
    
    func testRetrievingOldestMessage() {
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
    
    func testUpdateMessage() {
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
        _ = messagesManager.update(updatedMessage)
        
        XCTAssertNotEqual(messagesManager.messages.last!.message, originalMessageText)
        XCTAssertEqual(messagesManager.messages.last!.message, updatedMessageText)
        XCTAssertEqual(messagesManager.messages.last!.uuid, originalMessage.uuid)
    }
}

internal extension MessagesManagerTests {
    
    @discardableResult
    func addInfoMessageAndFirstUserMessage() -> [IndexPath] {
        setWelcomeMessage()
        messagesManager.loadCachedData()
        
        let firstMessage = createUserMessage("Good morning")
        return messagesManager.add(firstMessage)
    }
    
    func setWelcomeMessage() {
        XCTAssertTrue(dataSource.set(MESSAGE_WELCOME_TEXT, forKey: kParleyCacheKeyMessageInfo))
    }
    
    func createUserMessage(_ message: String, date: Date = Date()) -> Message {
        let userMessage = Message()
        userMessage.message = message
        userMessage.time = date
        userMessage.type = .user
        return userMessage
    }
    
    func getYesterdayDate() -> Date? {
        let today = Date()
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) else { return nil }
        return yesterday
    }
}
