import Foundation

final class DeviceRemoteService {

    private let remote: ParleyRemote

    init(remote: ParleyRemote) {
        self.remote = remote
    }

    func store(
        _ device: Device,
        onSuccess: @escaping (_ device: Device) -> (),
        onFailure: @escaping (_ error: Error) -> ()
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
