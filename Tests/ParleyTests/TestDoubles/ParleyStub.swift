@testable import Parley

final class ParleyStub: ParleyProtocol {

    init(
        messagesManager: MessagesManagerProtocol,
        messageRepository: MessageRepositoryProtocol,
        mediaLoader: MediaLoaderProtocol,
        localizationManager: LocalizationManager,
        messagesInteractor: MessagesInteractor,
        messagesPresenter: MessagesPresenterProtocol,
        messagesStore: MessagesStore
    ) {
        self.messagesManager = messagesManager
        self.messageRepository = messageRepository
        self.mediaLoader = mediaLoader
        self.localizationManager = localizationManager
        self.messagesInteractor = messagesInteractor
        self.messagesPresenter = messagesPresenter
        self.messagesStore = messagesStore
    }

    var state: Parley.State = .configured
    var reachable = true
    var alwaysPolling = false
    var pushEnabled = true

    var messagesManager: MessagesManagerProtocol?
    var messageRepository: MessageRepositoryProtocol!
    var mediaLoader: MediaLoaderProtocol!
    var localizationManager: LocalizationManager
    var messagesInteractor: MessagesInteractor!
    var messagesPresenter: MessagesPresenterProtocol!
    var messagesStore: MessagesStore!

    var delegate: ParleyDelegate?

    func isCachingEnabled() -> Bool {
        true
    }

    func send(_ message: Message, isNewMessage: Bool) async {}
    func send(_ text: String, silent: Bool) {}
    func userStartTyping() {}
    func loadMoreMessages(_ lastMessageId: Int) {}
    func sendNewMessageWithMedia(_ media: MediaModel) async {}

    func setLocalizationManager(_ localizationManager: LocalizationManager) {
        self.localizationManager = localizationManager
    }
}
