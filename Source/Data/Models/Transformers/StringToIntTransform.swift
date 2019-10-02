import ObjectMapper

class StringToIntTransform: TransformType {
    
    typealias Object = Int
    typealias JSON = String
    
    func transformFromJSON(_ value: Any?) -> Int? {
        if let value = value as? String {
            return Int(value)
        }
        
        return nil
    }
    
    func transformToJSON(_ value: Int?) -> String? {
        if let value = value {
            return String(value)
        }
        
        return nil
    }
}

