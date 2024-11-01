import Foundation
import UIKit

extension Date {

    func asDate(style: DateFormatter.Style = .medium) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = style

        return dateFormatter.string(from: self)
    }

    func asTime() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short

        return dateFormatter.string(from: self)
    }
}
