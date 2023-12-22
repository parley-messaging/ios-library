import Alamofire

internal class DeviceRemoteService {
    
    internal func store(_ device: Device, onSuccess: @escaping (_ device: Device)->(), onFailure: @escaping (_ error: Error)->()) {
        ParleyRemote.execute(HTTPMethod.post, "devices", parameters: try? CodableHelper.shared.toDictionary(device), onSuccess: onSuccess, onFailure: onFailure)
    }
}
