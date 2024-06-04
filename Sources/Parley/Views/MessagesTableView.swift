import UIKit

final class MessagesTableView: UITableView {

    private(set) var isAtBottom = false

    override var contentSize: CGSize {
        didSet {
            checkIsAtBottom()
        }
    }

    enum ScrollPosition {
        case top
        case bottom
    }

    func scroll(to: ScrollPosition, animated: Bool) {
        switch to {
        case .bottom:
            let section = max(0, numberOfSections - 1)
            let row = numberOfRows(inSection: section) - 1
            guard section >= 0 && row >= 0 else { return }

            let indexPath = IndexPath(row: row, section: section)
            scrollToRow(at: indexPath, at: .bottom, animated: animated)
            isAtBottom = true
        case .top:
            guard numberOfRows(inSection: 0) > 0 else { return }
            let indexPath = IndexPath(row: 0, section: 0)
            scrollToRow(at: indexPath, at: .top, animated: animated)
            isAtBottom = false
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

    func scrollViewDidScroll() {
        checkIsAtBottom()
    }

    private func checkIsAtBottom() {
        let padding: CGFloat = 16
        isAtBottom = contentOffset.y + frame.height + padding >= contentSize.height
    }
}
