import UIKit

struct ParleyLocalizationManager: LocalizationManager {
    func getLocalization(key: L10nKey) -> String {
        NSLocalizedString(key.rawValue, bundle: .module, comment: "")
    }
}
