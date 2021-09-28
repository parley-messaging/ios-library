import Foundation

protocol PollingServiceProtocol {
    func startRefreshing()
    var delegate: ParleyDelegate? { get set }
}

class PollingService: PollingServiceProtocol {
    
    private enum TimerInterval: TimeInterval {
        case twoSeconds = 2
        case fiveSeconds = 5
        case tenSeconds = 10
        case thirtySeconds = 30
    }
    
    private var timer: Timer?
    weak var delegate: ParleyDelegate?
    private let messageRepository = MessageRepository()
    private let messagesManager = Parley.shared.messagesManager
    
    private var loopRepeated: Int = 0 {
        didSet {
            if loopRepeated == 5 {
                switch timerInterval {
                case .twoSeconds:
                    timerInterval = .fiveSeconds
                case .fiveSeconds:
                    timerInterval = .tenSeconds
                case .tenSeconds:
                    timerInterval = .thirtySeconds
                default: break
                }
                loopRepeated = 0
            }
        }
    }
    private var timerInterval: TimerInterval = .twoSeconds {
        didSet {
            timer?.invalidate()
            setTimer(interval: timerInterval)
        }
    }
    
    func startRefreshing() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setTimer(interval: .twoSeconds)
        }
    }
    
    private func setTimer(interval: TimerInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: interval.rawValue, repeats: true) { [weak self] _ in
            self?.refreshFeed()
        }
    }
    
    private func refreshFeed() {
        guard let id = messagesManager.lastMessage?.id else { return }
        messageRepository.findAfter(id, onSuccess: { [weak self, weak delegate, weak messagesManager] messageCollection in
            guard !messageCollection.messages.isEmpty else {
                self?.loopRepeated += 1
                return
            }
            self?.loopRepeated = 0
            self?.timerInterval = .twoSeconds
            messagesManager?.handle(messageCollection, .all)
            delegate?.didReceiveMessages()
        }, onFailure: { error in
            print("Polling failed")
        })
    }
}
