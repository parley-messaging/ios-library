import Foundation

extension ParleyLocalizationKey {
    func localized(arguments: CVarArg...) -> String {
        Parley.shared.localizationManager.getLocalization(key: self, arguments: arguments)
    }
}
