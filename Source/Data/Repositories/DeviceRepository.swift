import UserNotifications

internal class DeviceRepository {
    
    private let deviceService = DeviceRemoteService()
    
    internal func register(_ onSuccess: @escaping (_ device: Device)->(), _ onFailure: @escaping (_ error: Error)->()) {
        let device = Device()
        
        device.pushToken = Parley.shared.pushToken
        device.pushType = Parley.shared.pushType
        device.pushEnabled = Parley.shared.pushEnabled
        
        device.userAdditionalInformation = Parley.shared.userAdditionalInformation
        
        device.referrer = Parley.shared.referrer
        
        self.store(device, onSuccess: onSuccess, onFailure: onFailure)
    }
    
    private func store(_ device: Device, onSuccess: @escaping (_ device: Device)->(), onFailure: @escaping (_ error: Error)->()) {
        self.deviceService.store(device, onSuccess: onSuccess, onFailure: onFailure)
    }
}
