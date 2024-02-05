import Alamofire
import Foundation
import Parley

extension Request: RequestCancable {
    public func cancelRequest() {
        cancel()
    }
}
