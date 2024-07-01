import Foundation

public protocol Queue {

    @preconcurrency
    func async(execute work: @escaping @Sendable @convention(block) () -> Void)

}

extension DispatchQueue: Queue {

    @preconcurrency
    public func async(execute work: @escaping @Sendable @convention(block) () -> Void) {
        async(group: nil, qos: .userInitiated, flags: [], execute: work)
    }
}
