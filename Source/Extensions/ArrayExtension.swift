import Foundation

extension Array {
    internal subscript(safe index: Index) -> Element? {
        guard index >= .zero, index < self.indices.count else { return nil }
        return self[index]
    }
}
