import Foundation

extension ParleyLocalizationKey {
    
    @MainActor func localized(arguments: CVarArg...) -> String {
        Parley.shared.localizationManager.getLocalization(key: self, arguments: arguments)
    }
}
