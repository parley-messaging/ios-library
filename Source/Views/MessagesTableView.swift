import UIKit

internal class MessagesTableView: UITableView {
    
    internal enum ScrollPosition {
        case top
        case bottom
    }
    
    internal func scroll(to: ScrollPosition, animated: Bool) {
        switch to {
        case .bottom:
            let section = max(0, numberOfSections - 1)
            let row = numberOfRows(inSection: section) - 1
            guard section >= 0 && row >= 0 else { return }
            
            let indexPath = IndexPath(row: row, section: section)
            scrollToRow(at: indexPath, at: .bottom, animated: animated)
        case .top:
            guard numberOfRows(inSection: 0) > 0 else { return }
            let indexPath = IndexPath(row: 0, section: 0)
            scrollToRow(at: indexPath, at: .top, animated: animated)
        }
    }
    
    override func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        UIView.setAnimationsEnabled(false)
        super.insertRows(at: indexPaths, with: animation)
        UIView.setAnimationsEnabled(true)
    }
    
    override func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        UIView.setAnimationsEnabled(false)
        super.deleteRows(at: indexPaths, with: animation)
        UIView.setAnimationsEnabled(true)
    }
    
    override func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        UIView.setAnimationsEnabled(false)
        super.reloadRows(at: indexPaths, with: animation)
        UIView.setAnimationsEnabled(true)
    }
}
