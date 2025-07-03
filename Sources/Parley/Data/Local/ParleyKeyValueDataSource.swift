import Foundation

public protocol ParleyKeyValueDataSource: AnyObject, ParleyDataSource, Sendable {

    func string(forKey key: String) async -> String?
    func data(forKey key: String) async -> Data?

    @discardableResult
    func set(_ string: String, forKey key: String) async -> Bool

    @discardableResult
    func set(_ data: Data, forKey key: String) async -> Bool

    @discardableResult
    func removeObject(forKey key: String) async -> Bool
}
