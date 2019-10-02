public class ParleyNetwork {
        
    var url: String
    var path: String
    
    var pin1: String
    var pin2: String
    
    var headers: [String:String]
    
    init () {
        self.url = kParleyNetworkUrl
        self.path = kParleyNetworkPath
        
        self.pin1 = kParleyNetworkPin1
        self.pin2 = kParleyNetworkPin2
        
        self.headers = [:]
    }
    
    public init (url: String, path: String, pin1: String, pin2: String, headers: [String:String] = [:]) {
        self.url = url
        self.path = path
        
        self.pin1 = pin1
        self.pin2 = pin2
        
        self.headers = headers
    }
}
