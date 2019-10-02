import UserNotifications

internal class DeviceRepository {
    
    private let deviceService = DeviceRemoteService()
    
    internal func register(_ onSuccess: @escaping (_ device: Device)->(), _ onFailure: @escaping (_ error: Error)->()) {
        let device = Device()
        
        if let pushToken = Parley.shared.pushToken {
            device.pushToken = pushToken
            device.pushEnabled = Parley.shared.pushEnabled
        }
        
        if let userAdditionalInformation = Parley.shared.userAdditionalInformation {
            device.userAdditionalInformation = userAdditionalInformation
        }
        
        self.store(device, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    private func store(_ device: Device, onSuccess: @escaping (_ device: Device)->(), onFailure: @escaping (_ error: Error)->()) {
        self.deviceService.store(device, onSuccess: onSuccess, onFailure: onFailure)
    }
}
