import Parley

extension Parley {
    
    /**
     Setup Parley Messaging without actually configuring it. Does not register the device or
     retrieve messages directly. Showing the chat will still require to call the configure method.
     
     - Parameters:
       - secret: Application secret of your Parley instance.
       - uniqueDeviceIdentifier: The device identifier to use for device registration.
       - networkSession: The network session that will handle all http traffic.
       - networkConfig: The configuration for the network.
     */
    public static func setup(
        secret: String,
        uniqueDeviceIdentifier: String? = nil,
        networkSession: ParleyNetworkSession? = nil,
        networkConfig: ParleyNetworkConfig? = nil,
    ) async {
        let config = networkConfig ?? ParleyNetworkConfig()
        await setup(
            secret: secret,
            uniqueDeviceIdentifier: uniqueDeviceIdentifier,
            networkSession: AlamofireNetworkSession(networkConfig: config),
            networkConfig: config
        )
    }
}

