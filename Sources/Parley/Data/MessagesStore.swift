import Foundation

@MainActor
final class MessagesStore {
    
    enum SectionKind: Equatable {
        /// Date is provided in case the welcome message posistion is set to `adaptive`
        case info(Date?)
        case loading
        
        /// Date is provided in case the welcome message posistion is set to `default`
        case messages(Date?)
        case typingIndicator
    }
    
    enum CellKind: Equatable {
        case info(String)
        case loading
        case message(Message)
        case carousel(mainMessage: Message, carousel: [Message])
        case typingIndicator
    }
    
    private var sections: [SectionKind]
    private var cells: [[CellKind]]
    private var readLock = NSLock()
    
    init() {
        cells = [[CellKind]]()
        sections = [SectionKind]()
    }
    
    func apply(snapshot: MessagesSnapshot) {
        assert(readLock.try() == false, "Lock should be locked when applying!")
        
        sections.removeAll(keepingCapacity: true)
        cells.removeAll(keepingCapacity: true)
        self.sections.reserveCapacity(snapshot.sections.endIndex - 1)
        
        for section in snapshot.sections {
            sections.append(section.sectionKind)
            let cellKinds = section.cells.map(\.kind)
            cells.append(cellKinds)
        }
    }
    
    func prepareForWrite() {
        readLock.lock()
    }
    
    func finishWrite() {
        readLock.unlock()
    }
}

// MARK: UITableView / UICollectionView methods
extension MessagesStore {
    
    var numberOfSections: Int {
        readLock.withLock {
            sections.count
        }
    }
    
    func numberOfRows(inSection section: Int) -> Int {
        readLock.withLock {
            cells[section].count
        }
    }
    
    func getMessage(at indexPath: IndexPath) -> Message? {
        readLock.withLock {
            if case let .message(message) = self[indexPath: indexPath] {
                return message
            }
            
            return nil
        }
    }
    
    func getCells(inSection section: Int) -> [CellKind] {
        readLock.withLock {
            cells[section]
        }
    }
    
    subscript(section sectionIndex: Int) -> SectionKind? {
        readLock.withLock {
            sections[safe: sectionIndex]
        }
    }
    
    subscript(section sectionIndex: Int, row rowIndex: Int) -> CellKind? {
        readLock.withLock {
            cells[sectionIndex][rowIndex]
        }
    }
    
    subscript(indexPath ip: IndexPath) -> CellKind? {
        readLock.withLock {
            return cell(at: ip)
        }
    }
}

// MARK: Privates
private extension MessagesStore {
    
    func cell(at ip: IndexPath) -> CellKind? {
        cells[safe: ip.section]?[safe: ip.row]
    }
}
