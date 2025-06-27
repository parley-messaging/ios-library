import Foundation
import Testing

extension Date {

    init!(timeIntSince1970: Int?) {
        guard let timeIntSince1970, timeIntSince1970 > 0 else {
            Issue.record("Input is not a valid timestamp") ; return nil
        }
        self = Date(timeIntervalSince1970: TimeInterval(timeIntSince1970))
    }
    

    init(daysSince1970 days: Int, offsetSeconds: Int = 0) {
        let seconds = (days * 86_400) + offsetSeconds
        self = Date(timeIntervalSince1970: TimeInterval(seconds))
    }
}
