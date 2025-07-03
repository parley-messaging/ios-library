@testable import Parley

final actor ParleyStub: ParleyProtocol {

    init(
        messagesManager: MessagesManagerProtocol,
        messageRepository: MessageRepository,
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

    private(set) var state: Parley.State = .configured
    
    private(set) var reachable = true
    private(set) var alwaysPolling = false
    private(set) var pushEnabled = true

    private(set) var messagesManager: MessagesManagerProtocol?
    private(set) var messageRepository: MessageRepository!
    private(set) var mediaLoader: MediaLoaderProtocol!
    private(set) var localizationManager: LocalizationManager
    private(set) var messagesInteractor: MessagesInteractor!
    private(set) var messagesPresenter: MessagesPresenterProtocol!
    private(set) var messagesStore: MessagesStore!

    @MainActor private(set) var delegate: ParleyDelegate?

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
   
    @MainActor
    func set(delegate: (any ParleyDelegate)?) async {
        self.delegate = delegate
    }
    
    func send(_ message: inout Message, isNewMessage: Bool) async {
        
    }
}

// MARK: Setters
extension ParleyStub {
    
    func set(state: Parley.State) {
        self.state = state
    }
    
    func set(reachable: Bool) {
        self.reachable = reachable
    }
    
    func set(alwaysPolling: Bool) {
        self.alwaysPolling = alwaysPolling
    }
    
    func set(pushEnabled: Bool) {
        self.pushEnabled = pushEnabled
    }
    
    func set(messagesManager: MessagesManagerProtocol?) {
        self.messagesManager = messagesManager
    }
}
