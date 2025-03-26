import Foundation
import Network

protocol PathProtocol: Sendable {
    var status: NWPath.Status { get }
}

extension NWPath: PathProtocol {}
