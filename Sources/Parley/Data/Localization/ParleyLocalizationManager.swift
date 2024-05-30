import UIKit

struct ParleyLocalizationManager: LocalizationManager {
    func getLocalization(key: ParleyLocalizationKey) -> String {
        NSLocalizedString(key.rawValue, bundle: .module, comment: "")
    }
}
