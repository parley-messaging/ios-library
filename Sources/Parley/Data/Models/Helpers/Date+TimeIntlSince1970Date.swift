import Foundation

extension Date {

    init?(timeIntSince1970: Int?) {
        guard let timeIntSince1970, timeIntSince1970 > 0 else {
            return nil
        }
        self = Date(timeIntervalSince1970: TimeInterval(timeIntSince1970))
    }
}
