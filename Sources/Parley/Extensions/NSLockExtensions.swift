import Foundation

extension NSLock {
    
    func withLock<R>(deadline: TimeInterval, opperation: () -> R) -> R {
        if lock(before: Date().addingTimeInterval(1)) {
            let value = opperation()
            unlock()
            return value
        } else {
            return opperation()
        }
    }
}
