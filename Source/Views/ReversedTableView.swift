import UIKit

internal class ReversedTableView: UITableView {
    
    enum ScrollTo {
        
        case top
        case bottom
    }

    private var secondaryDataSource: UITableViewDataSource?
    
    override var dataSource: UITableViewDataSource? {
        get {
            return self.secondaryDataSource
        }
        set {
            self.secondaryDataSource = newValue
        }
    }
    
    override var contentInset: UIEdgeInsets {
        get {
            return super.contentInset
        }
        set {
            super.contentInset = UIEdgeInsets(
                top: newValue.bottom,
                left: newValue.right,
                bottom: newValue.top,
                right: newValue.left
            )
        }
    }
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    private func setup() {
        super.dataSource = self
        
        self.transform = CGAffineTransform(scaleX: 1, y: -1)
    }
    
    internal func scroll(to: ScrollTo, animated: Bool) {
        switch to {
        case .top:
            let section = self.numberOfSections - 1
            let row = self.numberOfRows(inSection: section) - 1
            let indexPath = IndexPath(row: row, section: section)
            
            self.scrollToRow(at: indexPath, at: .bottom, animated: animated)
            
            break
        case .bottom:
            let indexPath = IndexPath(row: 0, section: 0)
            
            self.scrollToRow(at: indexPath, at: .top, animated: animated)
            
            break
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

extension ReversedTableView: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.secondaryDataSource?.tableView(tableView, numberOfRowsInSection: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableViewCell = self.secondaryDataSource?.tableView(tableView, cellForRowAt: indexPath) ?? UITableViewCell()
        tableViewCell.contentView.transform = CGAffineTransform(scaleX: 1, y: -1)
        
        return tableViewCell
    }
}
