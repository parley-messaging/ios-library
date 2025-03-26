import Foundation
import Network
@testable import Parley

public class PathStub: PathProtocol {
    public init(underlyingStatus: NWPath.Status) {
        self.underlyingStatus = underlyingStatus
    }

    public var status: NWPath.Status {
        get { return underlyingStatus }
        set(value) { underlyingStatus = value }
    }

    public var underlyingStatus: (NWPath.Status)!
}
