import UIKit

final class ObservableStackView: UIStackView {
    
    protocol BoundsDelegate: AnyObject {
        func boundsDidChange(for stackView: ObservableStackView, change: NSKeyValueObservedChange<CGRect>)
    }
    
    private var boundsObserver: NSKeyValueObservation?
    
    deinit {
        boundsObserver?.invalidate()
        boundsObserver = nil
    }
    
    func observeBounds(delegate: any BoundsDelegate) {
        boundsObserver = observe(\.self.bounds, options: [
            .initial,
            .new,
        ], changeHandler: { [weak delegate] stackView, change in
            delegate?.boundsDidChange(for: stackView, change: change)
        })
    }
}
