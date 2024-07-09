import Foundation
import Parley

public final class QueueSpy: Queue {

    public init() {
        // public init
    }

    // MARK: - async

    public var asyncExecuteCallsCount = 0
    public var asyncExecuteCalled: Bool {
        asyncExecuteCallsCount > 0
    }

    public var asyncExecuteReceivedWork: (() -> Void)?
    public var asyncExecuteReceivedInvocations: [() -> Void] = []
    public var asyncExecuteClosure: ((@convention(block) @escaping () -> Void) -> Void)?

    public func async(execute work: @convention(block) @escaping () -> Void) {
        asyncExecuteCallsCount += 1
        asyncExecuteReceivedWork = work
        asyncExecuteReceivedInvocations.append(work)
        asyncExecuteClosure?(work)
    }
}
