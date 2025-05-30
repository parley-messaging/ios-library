import Foundation
import Parley

extension Parley {

    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig? = nil,
        onSuccess: (@Sendable () -> Void)? = nil,
        onFailure: (@Sendable (_ code: Int, _ message: String) -> Void)? = nil
    ) {
        let localNetworkConfig = if let networkConfig { networkConfig } else { ParleyNetworkConfig() }

        configure(
            secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            networkConfig: localNetworkConfig,
            networkSession: AlamofireNetworkSession(networkConfig: localNetworkConfig),
            onSuccess: onSuccess,
            onFailure: onFailure
        )
    }

    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig? = nil,
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
