import Foundation

public protocol ParleyKeyValueDataSource: AnyObject, ParleyDataSource {

    func string(forKey key: String) -> String?
    func data(forKey key: String) -> Data?

    @discardableResult
    func set(_ string: String?, forKey key: String) -> Bool
    @discardableResult
    func set(_ data: Data?, forKey key: String) -> Bool

    @discardableResult
    func removeObject(forKey key: String) -> Bool
}
