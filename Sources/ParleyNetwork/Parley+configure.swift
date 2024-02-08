import Foundation
import Parley

extension Parley {

    public static func configure(
        _ secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkConfig: ParleyNetworkConfig? = nil,
        onSuccess: (() -> ())? = nil,
        onFailure: ((_ code: Int, _ message: String) -> ())? = nil
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
}
