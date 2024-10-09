public protocol LocalizationManager {
    func getLocalization(key: ParleyLocalizationKey, arguments: CVarArg...) -> String
}
