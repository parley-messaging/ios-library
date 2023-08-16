import Foundation

extension String {
    
    /// Appends a string to the current string while maintaining a maximum of a single space character between words.
    /// - Parameter string: the string to be appended at the end of `self`.
    ///
    /// - Important: The input string **shouldn't** start with a space.
    mutating func appendWithCorrectSpacing(_ string: String) {
        guard !string.isEmpty else { return }
        guard !isEmpty else { self = string ; return }
        
        if let lastCharacter = self.last, lastCharacter != " " {
            self.append(" ")
        }
        
        self.append(string)
    }
}
