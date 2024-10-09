import UIKit

struct ParleyLocalizationManager: LocalizationManager {
    func getLocalization(key: ParleyLocalizationKey, arguments: CVarArg...) -> String {
        let translatedString = NSLocalizedString(key.rawValue, bundle: .module, comment: "")
        if arguments.isEmpty {
            return translatedString
        } else {
            return String(format: translatedString, locale: nil, arguments: arguments)
        }
    }
}
