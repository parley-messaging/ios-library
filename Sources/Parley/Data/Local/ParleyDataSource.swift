public protocol ParleyDataSource: ParleyKeyValueDataSource, ParleyMessageDataSource {
    
    @discardableResult func clear() -> Bool
}
