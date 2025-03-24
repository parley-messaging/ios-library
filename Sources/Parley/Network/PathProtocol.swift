import Foundation
import Network

protocol PathProtocol {
    var status: NWPath.Status { get }
}

extension NWPath: PathProtocol {}
