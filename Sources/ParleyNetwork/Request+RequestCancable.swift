import Alamofire
import Foundation
import Parley

extension Request: RequestCancelable {
    public func cancelRequest() {
        cancel()
    }
}
