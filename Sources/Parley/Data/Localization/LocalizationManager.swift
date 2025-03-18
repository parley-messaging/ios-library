public protocol LocalizationManager: Sendable {
    func getLocalization(key: ParleyLocalizationKey, arguments: CVarArg...) -> String
}
