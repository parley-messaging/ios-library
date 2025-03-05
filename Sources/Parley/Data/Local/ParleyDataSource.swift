public protocol ParleyDataSource: AnyObject {

    @discardableResult
    func clear() async -> Bool
}
