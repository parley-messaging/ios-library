import Foundation
import Parley

extension Parley {

    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig? = nil,
        onSuccess: (() -> Void)? = nil,
        onFailure: ((_ code: Int, _ message: String) -> Void)? = nil
    ) async -> Parley.ConfigurationResult {
        let localNetworkConfig = networkConfig ?? ParleyNetworkConfig()

        return await configure(
            secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            networkConfig: localNetworkConfig,
            networkSession: AlamofireNetworkSession(networkConfig: localNetworkConfig)
        )
    }
}
