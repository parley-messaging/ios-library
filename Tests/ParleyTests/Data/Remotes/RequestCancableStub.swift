import Foundation
import Parley

struct RequestCancableStub: RequestCancable {
    func cancelRequest() { }
}
