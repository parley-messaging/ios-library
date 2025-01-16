import Foundation

extension Date {

    init?(timeIntSince1970: Int?) {
        guard let timeIntSince1970, timeIntSince1970 > 0 else {
            return nil
        }
        self = Date(timeIntervalSince1970: TimeInterval(timeIntSince1970))
    }
    
    init(daysSince1970 days: Int, offset: Int = 0) {
        let seconds = (days * 86_400) + offset
        self = Date(timeIntervalSince1970: TimeInterval(seconds))
    }
}
