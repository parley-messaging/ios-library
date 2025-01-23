import Foundation

extension Array {
    
    subscript(safe index: Index) -> Element? {
        guard index >= .zero, index < indices.endIndex else { return nil }
        return self[index]
    }
}
