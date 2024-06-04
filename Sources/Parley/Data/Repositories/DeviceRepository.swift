import UserNotifications

final class DeviceRepository {

    private let remote: ParleyRemote
    private let deviceService: DeviceRemoteService

    init(remote: ParleyRemote) {
        self.remote = remote
        deviceService = DeviceRemoteService(remote: remote)
    }

    func register(
        device: Device,
        onSuccess: @escaping (_ device: Device) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        deviceService.store(device, onSuccess: onSuccess, onFailure: onFailure)
    }
}
