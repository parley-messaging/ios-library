import Foundation

class MessagesStore {
    
    enum SectionKind {
        case info
        case loading
        case messages(Date, [Message])
        case typingIndicator
    }
    
    enum CellKind {
        case info(String)
        case loading
        case dateHeader(Date)
        case message(Message)
        case typingIndicator
    }
    
    private(set) var sections: [SectionKind]
    private var cells: [[CellKind]]
    
    init() {
        cells = [[CellKind]]()
        sections = [SectionKind]()
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
    
    func addSection(cells: [CellKind]) {
        self.cells[self.cells.endIndex] = cells
    }
    
    func insert(cell: CellKind, section: Int, row: Int) {
        cells[section][row] = cell
    }
    
    func removeSection(at index: Int) {
        cells.remove(at: index)
    }
    
    func rows(section: Int) -> Int {
        guard let section = cells[safe: section] else { return .zero }
        return section.count
    }
}
