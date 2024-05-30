import Foundation
import UIKit

protocol PollingServiceProtocol: AnyObject {
    func startRefreshing()
    func stopRefreshing()
    var delegate: ParleyDelegate? { get set }
}

final class PollingService: PollingServiceProtocol {
    
    private enum TimerInterval: TimeInterval {
        case twoSeconds = 2
        case fiveSeconds = 5
        case tenSeconds = 10
        case thirtySeconds = 30
    }
    
    private var timer: Timer?
    weak var delegate: ParleyDelegate?
    private lazy var messageRepository = Parley.shared.messageRepository
    private lazy var messagesManager = Parley.shared.messagesManager
    
    private var loopRepeated: Int = 0 {
        didSet {
            if loopRepeated >= 5 {
                switch timerInterval {
                case .twoSeconds:
                    timerInterval = .fiveSeconds
                case .fiveSeconds:
                    timerInterval = .tenSeconds
                case .tenSeconds:
                    timerInterval = .thirtySeconds
                default: break
                }
                setTimer(interval: timerInterval)
                loopRepeated = 0
            }
        }
    }
    private var timerInterval: TimerInterval = .twoSeconds {
        didSet { timer?.invalidate() }
    }
    
    func startRefreshing() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.setTimer(interval: .twoSeconds)
            self.addObservers()
        }
    }
    
    func stopRefreshing() {
        timer?.invalidate()
        loopRepeated = 0
        timerInterval = .twoSeconds
        timer = nil
        removeObservers()
    }
    
    private func setTimer(interval: TimerInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: interval.rawValue, repeats: true) { [weak self] _ in
            self?.refreshFeed()
        }
    }
    
    private func refreshFeed() {
        guard let messageRepository, let id = messagesManager?.lastSentMessage?.id, timer?.isValid == true else { return }
        messageRepository.findAfter(id, onSuccess: { [weak self, weak delegate, weak messagesManager] messageCollection in
            guard !messageCollection.messages.isEmpty else {
                self?.loopRepeated += 1
                return
            }
            self?.loopRepeated = 0
            self?.timerInterval = .twoSeconds
            self?.setTimer(interval: .twoSeconds)
            messagesManager?.handle(messageCollection, .all)
            delegate?.didReceiveMessages()
        }, onFailure: { error in
            print("Polling failed to retrieve latest messages")
        })
    }
    
    // MARK: - Observers

    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
   
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func willEnterForeground() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer?.invalidate()
            self.timer = nil
            self.setTimer(interval: self.timerInterval)
        }
    }
    
    @objc private func didEnterBackground() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
        }
    }
}
