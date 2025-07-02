import Foundation

final class DeviceRemoteService {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }

    func store(_ device: Device) async throws -> Device {
        try await remote.execute(.post, path: "devices", body: device)
    }
}
