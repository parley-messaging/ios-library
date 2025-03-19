import Foundation
import UIKit

@MainActor
protocol PollingServiceProtocol: Sendable, AnyObject {
    func startRefreshing() async
    func stopRefreshing() async
}

@MainActor
final class PollingService: PollingServiceProtocol {

    private enum TimerInterval: TimeInterval {
        case twoSeconds = 2
        case fiveSeconds = 5
        case tenSeconds = 10
        case thirtySeconds = 30
    }

    private var timer: Timer?
    private let messageRepository: MessageRepository
    private let messagesManager: MessagesManagerProtocol
    private let messagesInteractor: MessagesInteractor

    init(
        messageRepository: MessageRepository,
        messagesManager: MessagesManagerProtocol,
        messagesInteractor: MessagesInteractor
    ) {
        self.messageRepository = messageRepository
        self.messagesManager = messagesManager
        self.messagesInteractor = messagesInteractor
    }

    private var loopRepeated = 0 {
        didSet {
            if loopRepeated >= 5 {
                switch timerInterval {
                case .twoSeconds:
                    timerInterval = .fiveSeconds
                case .fiveSeconds:
                    timerInterval = .tenSeconds
                case .tenSeconds:
                    timerInterval = .thirtySeconds
                case .thirtySeconds:
                    timerInterval = .thirtySeconds
                }
                setTimer(interval: timerInterval)
                loopRepeated = 0
            }
        }
    }

    private var timerInterval: TimerInterval = .twoSeconds {
        didSet { timer?.invalidate() }
    }

    func startRefreshing() async {
        await MainActor.run {
            setTimer(interval: .twoSeconds)
            addObservers()
        }
    }

    func stopRefreshing() async {
        await MainActor.run {
            timer?.invalidate()
            loopRepeated = 0
            timerInterval = .twoSeconds
            timer = nil
            removeObservers()
        }
    }

    private func setTimer(interval: TimerInterval) {
        timer = Timer.scheduledTimer(withTimeInterval: interval.rawValue, repeats: true) { [weak self] _ in
            Task {
                await self?.refreshFeed()
            }
        }
    }

    private func refreshFeed() async {
        guard
            let id = await messagesManager.lastSentMessage?.remoteId,
            timer?.isValid == true else
        {
            return
        }
        
        do {
            let messageCollection = try await messageRepository.findAfter(id)
            guard !messageCollection.messages.isEmpty else {
                loopRepeated += 1
                return
            }
            loopRepeated = 0
            timerInterval = .twoSeconds
            setTimer(interval: .twoSeconds)
            await messagesInteractor.handle(collection: messageCollection, .after)
        } catch {
            print("Polling failed to retrieve latest messages: \(error.localizedDescription)")
        }
    }

    // MARK: - Observers

    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func willEnterForeground() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            timer?.invalidate()
            timer = nil
            setTimer(interval: timerInterval)
        }
    }

    @objc
    private func didEnterBackground() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
        }
    }
}
