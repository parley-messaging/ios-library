public protocol ParleyDataSource: AnyObject {

    @discardableResult
    func clear() -> Bool
}
