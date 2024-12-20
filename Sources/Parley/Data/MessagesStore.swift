import Foundation

class MessagesStore {
    
    enum SectionKind {
        case info
        case loading
        case messages
        case typingIndicator
    }
    
    enum CellKind: Equatable {
        case info(String)
        case loading
        case dateHeader(Date)
        case message(Message)
        case carousel(mainMessage: Message, carousel: [Message])
        case typingIndicator
    }
    
    private(set) var sections: [SectionKind]
    private(set) var cells: [[CellKind]]
    
    init() {
        cells = [[CellKind]]()
        sections = [SectionKind]()
    }
    
    func apply(snapshot: MessagesPresenter.Snapshot) {
        self.sections = snapshot.sections
        self.cells = snapshot.cells
    }
}

// MARK: UITableView / UICollectionView methods
extension MessagesStore {
    
    func rows(section: Int) -> Int {
        cells[section].count
    }
    
    func get(at indexPath: IndexPath) -> CellKind? {
        cells[indexPath.section][indexPath.row]
    }
    
    func getMessage(at indexPath: IndexPath) -> Message? {
        if case let .message(message) = get(at: indexPath) {
            return message
        }
        
        return nil
    }
}
