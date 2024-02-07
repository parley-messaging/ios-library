import Foundation
import Parley

struct RequestCancelableStub: RequestCancelable {
    func cancelRequest() { }
}
