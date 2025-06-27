import UserNotifications

final class DeviceRepository: Sendable {

    private let deviceService: DeviceRemoteService

    init(remote: ParleyRemote) {
        deviceService = DeviceRemoteService(remote: remote)
    }

    func register(device: Device) async throws -> Device {
        try await deviceService.store(device)
    }
}
