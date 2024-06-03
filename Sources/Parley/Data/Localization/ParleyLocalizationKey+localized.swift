import Foundation

extension ParleyLocalizationKey {
    var localized: String {
        Parley.shared.localizationManager.getLocalization(key: self)
    }
}
