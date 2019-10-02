import ObjectMapper

class StringToURLTransform: TransformType {
    
    typealias Object = URL
    typealias JSON = String
    
    func transformFromJSON(_ value: Any?) -> URL? {
        if let value = value as? String {
            return URL(string: value)
        }
        
        return nil
    }
    
    func transformToJSON(_ value: URL?) -> String? {
        if let value = value {
            return value.absoluteString
        }
        
        return nil
    }
}

