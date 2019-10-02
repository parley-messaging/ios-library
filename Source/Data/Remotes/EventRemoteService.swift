import Alamofire

internal class EventRemoteService {
    
    internal func fire(_ name: String, onSuccess: @escaping () -> (), onFailure: @escaping (_ error: Error) -> ()) {
        ParleyRemote.execute(.post, "services/event/\(name)", onSuccess: onSuccess, onFailure: onFailure)
    }
}
