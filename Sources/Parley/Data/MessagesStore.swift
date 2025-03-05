import Foundation

class MessagesStore {
    
    enum SectionKind: Equatable {
        case info
        case loading
        case messages(Date)
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
    
    init() {
        cells = [[CellKind]]()
        sections = [SectionKind]()
    }
    
    func apply(snapshot: MessagesPresenter.Snapshot) {
        sections.removeAll(keepingCapacity: true)
        cells.removeAll(keepingCapacity: true)
        self.sections.reserveCapacity(snapshot.sections.endIndex - 1)
        
        for section in snapshot.sections {
            sections.append(section.sectionKind)
            let cellKinds = section.cells.map(\.kind)
            cells.append(cellKinds)
        }
    }
}

// MARK: UITableView / UICollectionView methods
extension MessagesStore {
    
    var numberOfSections: Int {
        sections.count
    }
    
    func numberOfRows(inSection section: Int) -> Int {
        cells[section].count
    }
    
    func getMessage(at indexPath: IndexPath) -> Message? {
        if case let .message(message) = self[indexPath: indexPath] {
            return message
        }
        
        return nil
    }
    
    func getCells(inSection section: Int) -> [CellKind] {
        cells[section]
    }
    
    subscript(section sectionIndex: Int) -> SectionKind? {
        return sections[safe: sectionIndex]
    }
    
    subscript(section sectionIndex: Int, row rowIndex: Int) -> CellKind? {
        cells[sectionIndex][rowIndex]
    }
    
    subscript(indexPath ip: IndexPath) -> CellKind? {
        cells[safe: ip.section]?[safe: ip.row]
    }
}
