import Foundation
import Parley

struct RequestCancelableStub: ParleyRequestCancelable {
    func cancelRequest() { }
}
