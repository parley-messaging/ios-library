struct UnseenMessagesResponse: Codable {
    let messageIds: [Int]
    let count: Int
    
    func toDomainModel() -> UnseenMessages {
        UnseenMessages(messageIds: messageIds, count: count)
    }
}
