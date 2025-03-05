import Foundation
import Parley

extension Parley {

    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig? = nil
    ) async -> ParleyActor.ConfigurationResult {
        let localNetworkConfig = networkConfig ?? ParleyNetworkConfig()

        return await configure(
            secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            networkConfig: localNetworkConfig,
            networkSession: AlamofireNetworkSession(networkConfig: localNetworkConfig)
        )
    }
}
