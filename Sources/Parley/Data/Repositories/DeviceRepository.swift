import UserNotifications

class DeviceRepository {

    private let remote: ParleyRemote
    private let deviceService: DeviceRemoteService

    public init(remote: ParleyRemote) {
        self.remote = remote
        deviceService = DeviceRemoteService(remote: remote)
    }

    func register(
        device: Device,
        onSuccess: @escaping (_ device: Device) -> (),
        onFailure: @escaping (_ error: Error) -> ()
    ) {
        deviceService.store(device, onSuccess: onSuccess, onFailure: onFailure)
    }
}
