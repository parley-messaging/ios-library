public class ParleyNetwork {
        
    var url: String
    var path: String
    
    var headers: [String:String]
    
    init () {
        self.url = kParleyNetworkUrl
        self.path = kParleyNetworkPath
        
        self.headers = [:]
    }
    
    public init (url: String, path: String, headers: [String:String] = [:]) {
        self.url = url
        self.path = path
        
        self.headers = headers
    }
}
