import UserNotifications

final class DeviceRepository {

    private let remote: ParleyRemote
    private let deviceService: DeviceRemoteService

    init(remote: ParleyRemote) {
        self.remote = remote
        deviceService = DeviceRemoteService(remote: remote)
    }

    func register(device: Device) async throws -> Device {
        try await deviceService.store(device)
    }
}
