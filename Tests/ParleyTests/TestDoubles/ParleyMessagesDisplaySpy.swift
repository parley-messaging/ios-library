import UIKit
@testable import Parley

@MainActor
final class ParleyMessagesDisplaySpy: ParleyMessagesDisplay {
    
    let appearance = ParleyViewAppearance()
    
    private(set) var performBatchUpdatesCallCount = 0
    private(set) var reloadCallCount = 0
    
    private(set) var displayStickyMessageCallCount = 0
    
    private(set) var displayHideStickyMessageCallCount = 0
    
    private(set) var displayQuickRepliesCallCount = 0
    private(set) var displayQuickRepliesLatestArguments: [String]?
    
    private(set) var displayHideQuickRepliesCallCount = 0
    
    private(set) var displayScrollToBottomCallCount = 0
    private(set) var displayScrollToBottomLatestArgument: Bool?
    
    private(set) var displayAttachedCallCount = 0
    
    var hasInteractedWithDisplay: Bool {
        reloadCallCount > 0 ||
        displayStickyMessageCallCount > 0 ||
        displayHideStickyMessageCallCount > 0
    }
    
    func performBatchUpdates(
        _ changes: SnapshotChange,
        preUpdate: (@MainActor @Sendable () -> Void)?,
        postUpdate: (@MainActor @Sendable () -> Void)?,
        completion: (@MainActor @Sendable () -> Void)?
    ) {
        performBatchUpdatesCallCount += 1
        preUpdate?()
        postUpdate?()
        completion?()
    }
    
    func reload() {
        reloadCallCount += 1
    }
    
    func display(stickyMessage: String) {
        displayStickyMessageCallCount += 1
    }
    
    func displayHideStickyMessage() {
        displayHideStickyMessageCallCount += 1
    }
    
    func display(quickReplies: [String]) {
        displayQuickRepliesCallCount += 1
        displayQuickRepliesLatestArguments = quickReplies
    }
    
    func displayHideQuickReplies() {
        displayHideQuickRepliesCallCount += 1
    }
    
    func displayScrollToBottom(animated: Bool) {
        displayScrollToBottomCallCount += 1
        displayScrollToBottomLatestArgument = animated
    }
    
    func signalAttached() async {
        displayAttachedCallCount += 1
    }
}
