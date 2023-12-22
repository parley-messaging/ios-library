import Foundation
import UIKit

extension Date {

    func asDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium

        return dateFormatter.string(from: self)
    }

    func asTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short

        return dateFormatter.string(from: self)
    }
}
