import ObjectMapper
import Foundation

class TimeIntervalSince1970DateTransform: TransformType {
    
    typealias Object = Date
    typealias JSON = Int

    func transformFromJSON(_ value: Any?) -> Date? {
        if let value = value as? Int, value > 0 {
            return  Date(timeIntervalSince1970: TimeInterval(value))
        }
        
        return nil
    }
    
    func transformToJSON(_ value: Date?) -> Int? {
        if let value = value {
            return Int(value.timeIntervalSince1970)
        }
        
        return nil
    }
}
