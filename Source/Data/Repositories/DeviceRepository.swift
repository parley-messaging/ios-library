import UserNotifications

internal class DeviceRepository {

    private let deviceService = DeviceRemoteService()

    func register(_ onSuccess: @escaping (_ device: Device)->(), _ onFailure: @escaping (_ error: Error)->()) {
        let device = Device(
            pushToken: Parley.shared.pushToken,
            pushType: Parley.shared.pushType,
            pushEnabled: Parley.shared.pushEnabled,
            userAdditionalInformation: Parley.shared.userAdditionalInformation,
            referrer: Parley.shared.referrer
        )

        store(device, onSuccess: onSuccess, onFailure: onFailure)
    }

    private func store(
        _ device: Device,
        onSuccess: @escaping (_ device: Device)->(),
        onFailure: @escaping (_ error: Error)->()
    ) {
        deviceService.store(device, onSuccess: onSuccess, onFailure: onFailure)
    }
}
