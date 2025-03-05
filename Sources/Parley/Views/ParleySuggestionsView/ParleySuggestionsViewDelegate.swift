protocol ParleySuggestionsViewDelegate: AnyObject {
    @MainActor func didSelect(_ suggestion: String)
}
