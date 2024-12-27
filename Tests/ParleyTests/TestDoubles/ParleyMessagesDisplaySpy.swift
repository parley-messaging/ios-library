import UIKit
@testable import Parley

class ParleyMessagesDisplaySpy: ParleyMessagesDisplay {
    private(set) var insertRowsCallCount = 0
    private(set) var insertRowsIndexPaths: [IndexPath]?
    
    private(set) var deleteRowsCallCount = 0
    private(set) var deleteRowsIndexPaths: [IndexPath]?
    
    private(set) var reloadRowsCallCount = 0
    private(set) var reloadRowsIndexPaths: [IndexPath]?
    
    private(set) var reloadCallCount = 0
    
    private(set) var displayStickyMessageCallCount = 0
    
    private(set) var displayHideStickyMessageCallCount = 0
    
    var hasInterhactedWithDisplay: Bool {
        insertRowsCallCount > 0 || insertRowsIndexPaths != nil ||
        deleteRowsCallCount > 0 || deleteRowsIndexPaths != nil ||
        reloadRowsCallCount > 0 || reloadRowsIndexPaths != nil ||
        reloadCallCount > 0 ||
        displayStickyMessageCallCount > 0 ||
        displayHideStickyMessageCallCount > 0
    }
    
    func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        insertRowsCallCount += 1
        insertRowsIndexPaths = indexPaths
    }
    
    func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        deleteRowsCallCount += 1
        deleteRowsIndexPaths = indexPaths
    }
    
    func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        reloadRowsCallCount += 1
        reloadRowsIndexPaths = indexPaths
    }
    
    func reload() {
        reloadCallCount += 1
    }
    
    func display(stickyMessage: String) {
        displayStickyMessageCallCount += 1
    }
    
    func displayHideStickyMessage() {
        displayHideStickyMessageCallCount += 1
    }
}
