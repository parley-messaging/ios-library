import Foundation
@testable import Parley

final class ParleyInMemoryKeyValueDataSource: ParleyKeyValueDataSource {

    private var dataDict = [String: Any]()

    func string(forKey key: String) -> String? {
        dataDict[key] as? String
    }

    func data(forKey key: String) -> Data? {
        dataDict[key] as? Data
    }

    func set(_ string: String, forKey key: String) -> Bool {
        dataDict[key] = string
        return true
    }

    func set(_ data: Data, forKey key: String) -> Bool {
        dataDict[key] = data
        return true
    }

    func removeObject(forKey key: String) -> Bool {
        dataDict[key] = nil
        return true
    }

    func clear() -> Bool {
        dataDict.removeAll()
        return true
    }
}
