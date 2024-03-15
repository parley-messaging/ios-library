import Alamofire
import Foundation
import Parley

extension Request: ParleyRequestCancelable {
    public func cancelRequest() {
        cancel()
    }
}
