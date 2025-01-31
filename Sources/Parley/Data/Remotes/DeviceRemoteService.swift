import Foundation

final class DeviceRemoteService {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }

    func store(
        _ device: Device,
        onSuccess: @escaping (_ device: Device) -> Void,
        onFailure: @escaping (_ error: Error) -> Void
    ) {
        remote.execute(
            .post,
            path: "devices",
            body: device,
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }
}

// MARK: Async Methods
extension DeviceRemoteService {
    
    func store(_ device: Device) async throws -> Device {
        try await remote.execute(.post, path: "devices", body: device)
    }
}
