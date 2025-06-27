import Combine
import Foundation

@MainActor
final class MessageReadWorker {
    
    protocol Delegate: AnyObject, Sendable {
        func didReadMessages(ids: Set<Int>) async
    }
    
    // MARK: Privates
    private let messageRepository: MessageRepository
    private var subscriptions = Set<AnyCancellable>()
    private var pendingIds = Set<Int>()
    private let submissionQueue = PassthroughSubject<Void, Never>()
    private weak var delegate: Delegate?

    init(
        messageRepository: MessageRepository,
        debounceInterval: TimeInterval = 1
    ) {
        self.messageRepository = messageRepository
        
        submissionQueue
            .debounce(for: .seconds(debounceInterval), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.flush()
            }
            .store(in: &subscriptions)
    }
    
    func set(delegate: Delegate) {
        self.delegate = delegate
    }
    
    func queueMessageRead(messageId: Int) {
        Task {
            pendingIds.insert(messageId)
            submissionQueue.send(())
        }
    }
}

// MARK: – Privates
private extension MessageReadWorker {

    func flush() {
        guard !pendingIds.isEmpty else { return }

        let idsToSend = pendingIds
        pendingIds.removeAll()

        Task {
            do {
                try await messageRepository.updateStatusRead(messageIds: idsToSend)
                await delegate?.didReadMessages(ids: idsToSend)
            } catch {
                pendingIds.formUnion(idsToSend)
            }
        }
    }
}
