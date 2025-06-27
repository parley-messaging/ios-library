protocol ReachabilityProvider: Sendable {
    var reachable: Bool { get async }
}
