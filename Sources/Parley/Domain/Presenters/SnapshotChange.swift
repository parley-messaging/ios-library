import Foundation

struct SnapshotChange: Equatable {
    var sectionChanges: [SectionChange] = []
    var rowChanges: [RowChange] = []
    
    struct SectionChange: Equatable {
        enum Kind: Equatable {
            case insert, delete, move(from: Int), reload
        }
        let section: Int
        let kind: Kind
    }
    
    struct RowChange: Equatable {
        enum Kind: Equatable {
            case insert, delete, move(from: IndexPath), reload
        }
        let indexPath: IndexPath
        let kind: Kind
    }
}

// MARK: Subscripts
extension SnapshotChange {
    
    subscript(section sectionIndex: Int, row rowIndex: Int) -> RowChange.Kind? {
        self.rowChanges.first { rowChange in
            rowChange.indexPath == IndexPath(row: rowIndex, section: sectionIndex)
        }?.kind
    }
    
    subscript(section sectionIndex: Int) -> SectionChange.Kind? {
        self.sectionChanges.first { $0.section == sectionIndex }?.kind
    }
}

extension SnapshotChange {

    var isEmpty: Bool {
        return sectionChanges.isEmpty && rowChanges.isEmpty
    }
}

extension [SnapshotChange.SectionChange] {
    
    var deletions: Self {
        filter { if case .delete = $0.kind { return true }; return false }
    }
    
    var insertions: Self {
        filter { if case .insert = $0.kind { return true }; return false }
    }
    
    var moves: Self {
        filter { if case .move = $0.kind { return true }; return false }
    }
    
    var reloads: Self {
        filter { if case .reload = $0.kind { return true }; return false }
    }
}

extension [SnapshotChange.RowChange] {
    
    var deletions: Self {
        filter { if case .delete = $0.kind { return true }; return false }
    }
    
    var insertions: Self {
        filter { if case .insert = $0.kind { return true }; return false }
    }
    
    var moves: Self {
        filter { if case .move = $0.kind { return true }; return false }
    }
    
    var reloads: Self {
        filter { if case .reload = $0.kind { return true }; return false }
    }
}
