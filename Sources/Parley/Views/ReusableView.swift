import Foundation
import UIKit

public protocol ReusableView {
    static var reuseIdentifier: String { get }
}

extension ReusableView {
    public static var reuseIdentifier: String {
        String(describing: self)
    }
}

extension UITableViewCell: ReusableView {}
extension UITableViewHeaderFooterView: ReusableView {}
extension UICollectionViewCell: ReusableView {}
