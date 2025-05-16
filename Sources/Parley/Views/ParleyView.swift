import UIKit
import UniformTypeIdentifiers

@MainActor
protocol ParleyMessagesDisplay: AnyObject {
    func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)
    func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)
    func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation)
    func scrollTo(indexPaths: IndexPath, at position: UITableView.ScrollPosition, animated: Bool)
    func displayScrollToBottom(animated: Bool)
    func reload()
    
    func display(quickReplies: [String])
    func displayHideQuickReplies()
    
    func display(stickyMessage: String)
    func displayHideStickyMessage()
}

@MainActor
public class ParleyView: UIView {
    
    // MARK: IBOutlets
    @IBOutlet var contentView: UIView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    private var tableViewTopPaddingTapGestureRecognizer: UITapGestureRecognizer?
    private var messagesContentHeightObserver: NSKeyValueObservation?
    @IBOutlet private weak var messagesTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private(set) weak var messagesTableView: MessagesTableView!
    @IBOutlet private weak var messagesTableViewPaddingToSafeAreaTopView: UIView!
    @IBOutlet weak var notificationsStackView: ObservableStackView!
    @IBOutlet weak var notificationsConstraintTop: NSLayoutConstraint!
    private weak var notificationsConstraintBottom: NSLayoutConstraint?
    @IBOutlet weak var pushDisabledNotificationView: ParleyNotificationView!
    @IBOutlet weak var offlineNotificationView: ParleyNotificationView!
    @IBOutlet weak var stickyView: ParleyStickyView!
    @IBOutlet weak var suggestionsView: ParleySuggestionsView!
    @IBOutlet weak var suggestionsConstraintBottom: NSLayoutConstraint!
    @IBOutlet weak var composeView: ParleyComposeView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    
    // MARK: Dependencies
    private var parley: ParleyProtocol!
    private var notificationService: NotificationServiceProtocol!
    private(set) var pollingService: PollingServiceProtocol?
    private var shareManager: ShareManager?
    private var messagesStore: MessagesStore!
    private var messagesInteractor: MessagesInteractor?
    private var messagesManager: MessagesManagerProtocol?
    private var mediaLoader: MediaLoaderProtocol!
    
    // MARK: Properties
    public weak var delegate: ParleyViewDelegate?
    private var isShowingKeyboardWithMessagesScrolledToBottom = false
    private var isAlreadyAtTop = false
    private var mostRecentSimplifiedDeviceOrientation: UIDeviceOrientation.Simplified = UIDevice.current.orientation.simplifiedOrientation ?? .portrait
    private static let maximumImageSizeInMegabytes = 10
    public var appearance = ParleyViewAppearance() {
        didSet {
            apply(appearance)
        }
    }

    @available(*, deprecated, renamed: "mediaEnabled", message: "Use mediaEnabled instead")
    public var imagesEnabled = true {
        didSet {
            mediaEnabled = imagesEnabled
        }
    }

    public var mediaEnabled = true {
        didSet {
            composeView.allowMediaUpload = mediaEnabled
        }
    }

    @MainActor
    init(
        parley: ParleyProtocol,
        pollingService: PollingServiceProtocol?,
        notificationService: NotificationServiceProtocol
    ) async {
        self.parley = parley
        self.notificationService = notificationService
        self.pollingService = pollingService
        super.init(frame: .zero)
        setupUI()
        await setup()
    }

    public required init() {
        self.parley = ParleyActor.shared
        self.notificationService = NotificationService()
        super.init(frame: .zero)
        setupUI()
        Task {
            await setup()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        self.parley = ParleyActor.shared
        self.notificationService = NotificationService()
        super.init(coder: aDecoder)
        setupUI()
        Task {
            await setup()
        }
    }

    deinit {
        removeObservers()
    }
    
    private func setup() async {
        await parley.messagesPresenter?.set(display: self)
        await setupDependencies()
        await parley.set(delegate: self)
        await messagesInteractor?.handleViewDidLoad()
    }
    
    private func setupDependencies() async {
        if let mediaLoader = await parley.mediaLoader {
            shareManager = try? ShareManager(mediaLoader: mediaLoader)
            self.mediaLoader = mediaLoader
        }
        messagesStore = await parley.messagesStore
        messagesInteractor = await parley.messagesInteractor
        switch await parley.state {
        case .unconfigured:
            messagesManager = nil
        case .configuring, .configured, .failed:
            messagesManager = await parley.messagesManager
        }
        
        await setupPollingIfNecessary()
    }

    private func setupPollingIfNecessary() async {
        guard
            pollingService == nil,
            let messagesManager else { return }

        let pollingService = PollingService(
            messageRepository: await parley.messageRepository,
            messagesManager: messagesManager,
            messagesInteractor: await parley.messagesInteractor
        )
        self.pollingService = pollingService

        if await parley.alwaysPolling {
            await pollingService.startRefreshing()
        } else {
            let isEnabled = await notificationService.notificationsEnabled()
            guard !isEnabled else { return }
            await pollingService.startRefreshing()
        }
    }
    
    @MainActor
    private func setupUI() {
        loadXib()
        
        contentView.backgroundColor = UIColor.clear
        pushDisabledNotificationView.text = ParleyLocalizationKey.pushDisabled.localized()
        offlineNotificationView.text = ParleyLocalizationKey.notificationOffline.localized()
        suggestionsView.delegate = self
        syncMessageTableViewContentInsets()
        composeView.placeholder = ParleyLocalizationKey.typeMessage.localized()
        composeView.placeholderVoiceOver = ParleyLocalizationKey.voiceOverTypeMessageLabel.localized()
        composeView.maxCount = kParleyMessageMaxCount
        
        composeView.delegate = self
        
        setupMessagesTableView()
        
        addObservers()
        
        notificationsStackView.observeBounds(delegate: self)
        suggestionsView.observeBounds(delegate: self)
    }
    
    private func loadXib() {
        Bundle.module.loadNibNamed("ParleyView", owner: self, options: nil)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        apply(appearance)
    }
    
    // MARK: Views
    private func setupMessagesTableView() {
        let cellIdentifiers = [
            InfoTableViewCell.reuseIdentifier,
            LoadingTableViewCell.reuseIdentifier,

            MessageTableViewCell.reuseIdentifier,
            AgentTypingTableViewCell.reuseIdentifier,
        ]

        for cellIdentifier in cellIdentifiers {
            registerNibCell(cellIdentifier)
        }

        messagesTableView.dataSource = self
        messagesTableView.delegate = self
        messagesTableView.separatorStyle = .none
        messagesTableView.keyboardDismissMode = .interactive
        messagesTableView.alwaysBounceVertical = false
        messagesTableView.estimatedSectionHeaderHeight = DateHeaderView.estimatedHeight
        messagesTableView.sectionHeaderHeight = UITableView.automaticDimension
        if #available(iOS 15.0, *) {
            messagesTableView.sectionHeaderTopPadding = 0
        }
        
        messagesTableView.observeContentHeight(delegate: self)
    }
}

extension ParleyView: @preconcurrency MessagesTableView.SizeDelegate {
    
    func sizeDidChange(for tableView: MessagesTableView, change: NSKeyValueObservedChange<CGSize>) {
        guard let newContentHeight = change.newValue?.height else { return }
        let verticalInsets = tableView.contentInset.top + tableView.contentInset.bottom
        let newHeight = newContentHeight + verticalInsets
        
        self.messagesTableViewHeightConstraint.constant = newHeight
        
        let isScrollable = newContentHeight > messagesTableView.frame.maxY
        if isScrollable {
            messagesTableView.keyboardDismissMode = .interactive
        } else {
            messagesTableView.keyboardDismissMode = .onDrag
        }
        self.updateSuggestionsAlpha()
    }
}

extension ParleyView {
    
    func reloadMessages() {
        messagesTableView.reloadData()
    }

    private func registerNibCell(_ nibName: String) {
        let tableViewCellNib = UINib(nibName: nibName, bundle: .module)
        messagesTableView.register(tableViewCellNib, forCellReuseIdentifier: nibName)
    }

    private func syncMessageTableViewContentInsets() {
        let top: CGFloat
        let bottom: CGFloat
        let notificationsHeight = getNotificationsHeight()
        let suggestionsHeight = getSuggestionsHeight()
        switch appearance.notificationsPosition {
        case .top:
            top = notificationsHeight
            bottom = suggestionsHeight
            suggestionsConstraintBottom.constant = 0
        case .bottom:
            top = 0
            bottom = suggestionsHeight + notificationsHeight
            suggestionsConstraintBottom.constant = notificationsHeight
        }

        messagesTableView.contentInset = UIEdgeInsets(
            top: top,
            left: 0,
            bottom: bottom,
            right: 0
        )

        if messagesTableView.isAtBottom {
            // Stay at bottom
            messagesTableView.scroll(to: .bottom, animated: true)
        }
    }

    private func getNotificationsHeight() -> CGFloat {
        notificationsStackView.frame.height
    }

    /// Gets the notification height for the specified vertical position based on the current appearance.
    /// - Parameters:
    ///  - position: Vertical position
    /// - Returns: Vertical height, `0` if the current appearance is not the
    private func getNotificationsHeight(for position: ParleyPositionVertical) -> CGFloat {
        guard appearance.notificationsPosition == position else { return .zero }
        return notificationsStackView.frame.height
    }

    private func getSuggestionsHeight() -> CGFloat {
        suggestionsView.isHidden ? 0 : suggestionsView.frame.height
    }

    // MARK: Observers
    private func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentSizeCategoryDidChange),
            name: UIContentSizeCategory.didChangeNotification,
            object: nil
        )
        watchForVoiceOverDidChangeNotification(observer: self)
    }

    nonisolated
    private func removeObservers() {
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillShowNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardDidShowNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillHideNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardDidHideNotification)
        NotificationCenter.default.removeObserver(UIDevice.orientationDidChangeNotification)
        NotificationCenter.default.removeObserver(UIContentSizeCategory.didChangeNotification)
        NotificationCenter.default.removeObserver(
            self,
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
    }

    // MARK: Keyboard
    @objc
    private func keyboardWillShow(notification: NSNotification) {
        messagesTableView.addGestureRecognizer(tapGestureRecognizer)

        if messagesTableView.isAtBottom {
            isShowingKeyboardWithMessagesScrolledToBottom = true
        }

        let topPaddingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        messagesTableViewPaddingToSafeAreaTopView.addGestureRecognizer(topPaddingTapGestureRecognizer)
        tableViewTopPaddingTapGestureRecognizer = topPaddingTapGestureRecognizer
    }

    @objc
    private func keyboardDidShow() {
        guard isShowingKeyboardWithMessagesScrolledToBottom else { return }
        messagesTableView.scroll(to: .bottom, animated: false)
        isShowingKeyboardWithMessagesScrolledToBottom = false
    }

    @objc
    private func keyboardWillHide(notification: NSNotification) {
        messagesTableView.removeGestureRecognizer(tapGestureRecognizer)
        if let tableViewTopPaddingTapGestureRecognizer {
            messagesTableViewPaddingToSafeAreaTopView.removeGestureRecognizer(tableViewTopPaddingTapGestureRecognizer)
            self.tableViewTopPaddingTapGestureRecognizer = nil
        }

        if messagesTableView.isAtBottom {
            isShowingKeyboardWithMessagesScrolledToBottom = true
        }
    }

    @objc
    private func keyboardDidHide() {
        syncMessageTableViewContentInsets()
        messagesTableView.scroll(to: .bottom, animated: true)
        
        guard isShowingKeyboardWithMessagesScrolledToBottom else { return }
        messagesTableView.scroll(to: .bottom, animated: true)
        isShowingKeyboardWithMessagesScrolledToBottom = false
    }

    @IBAction
    func hideKeyboard(_ sender: Any) {
        endEditing(true)
    }

    // MARK: Orientation
    @objc
    private func orientationDidChange() {
        // NOTE: Only reloading data if the orientation actually changed from landscape to portrait or vice versa.
        // NOTE: This also triggers when device went `faceUp` and `faceDown`. We ignore those triggers since we don't need these.
        guard let simplifiedOrientation = UIDevice.current.orientation.simplifiedOrientation,
              mostRecentSimplifiedDeviceOrientation != simplifiedOrientation else {
            return
        }
        
        mostRecentSimplifiedDeviceOrientation = simplifiedOrientation

        DispatchQueue.main.async {
            self.reloadMessages()
        }
    }

    // MARK: Appearance
    private func apply(_ appearance: ParleyViewAppearance) {
        backgroundColor = appearance.backgroundColor

        activityIndicatorView.color = appearance.loaderTintColor
        statusLabel.textColor = appearance.textColor

        pushDisabledNotificationView.appearance = appearance.pushDisabledNotification
        offlineNotificationView.appearance = appearance.offlineNotification
        stickyView.appearance = appearance.sticky
        composeView.appearance = appearance.compose

        suggestionsView.appearance = appearance.suggestions

        // Positioning
        switch appearance.notificationsPosition {
        case .top:
            if let bottomConstraint = notificationsConstraintBottom {
                // Reset to original
                notificationsConstraintBottom?.isActive = false
                notificationsStackView.removeConstraint(bottomConstraint)
                notificationsConstraintTop?.isActive = true
            }
        case .bottom:
            notificationsConstraintTop?.isActive = false
            notificationsConstraintBottom = notificationsStackView.bottomAnchor.constraint(
                equalTo: composeView.topAnchor,
                constant: 0
            )
            notificationsConstraintBottom?.isActive = true
        }
        reloadMessages()
    }
}

// MARK: ParleyDelegate
@MainActor
extension ParleyView: ParleyDelegate {

    func didSent(_ message: Message) {
        delegate?.didSentMessage()
        UIAccessibility.post(
            notification: .announcement,
            argument: ParleyLocalizationKey.voiceOverAnnouncementSentMessage.localized
        )
    }
    
    public func didChangeState(_ state: Parley.State) {
        debugPrint("ParleyViewDelegate.didChangeState:: \(state)")

        if state == .unconfigured {
            pollingService = nil
        }

        Task {
            await setupPollingIfNecessary()
        }

        switch state {
        case .unconfigured:
            reloadMessages()
            messagesTableView.isHidden = true
            composeView.isHidden = true
            suggestionsView.isHidden = true

            statusLabel.text = ParleyLocalizationKey.stateUnconfigured.localized()
            statusLabel.isHidden = false

            activityIndicatorView.isHidden = true
            activityIndicatorView.stopAnimating()

            stickyView.isHidden = true
        case .configuring:
            messagesTableView.isHidden = true
            composeView.isHidden = true
            statusLabel.isHidden = true
            suggestionsView.isHidden = true

            activityIndicatorView.isHidden = false
            activityIndicatorView.startAnimating()

            stickyView.isHidden = true
        case .failed:
            messagesTableView.isHidden = true
            composeView.isHidden = true
            suggestionsView.isHidden = true

            statusLabel.text = ParleyLocalizationKey.stateFailed.localized()
            statusLabel.isHidden = false

            activityIndicatorView.isHidden = true
            activityIndicatorView.stopAnimating()

            stickyView.isHidden = true
        case .configured:
            composeView.isHidden = false
            statusLabel.isHidden = true

            activityIndicatorView.isHidden = true
            activityIndicatorView.stopAnimating()

            Task { @MainActor in
                stickyView.text = await messagesManager?.stickyMessage
                stickyView.isHidden = await messagesManager?.stickyMessage == nil
                
                reloadMessages()
                
                messagesTableView.scroll(to: .bottom, animated: false)

                DispatchQueue.main.async { [weak self] in
                    self?.messagesTableView.scroll(to: .bottom, animated: false)
                    self?.updateSuggestionsAlpha() // For VoiceOver
                    self?.messagesTableView.isHidden = false
                }
            }
        }
    }

    public func didChangePushEnabled(_ pushEnabled: Bool) {
        if offlineNotificationView.isHidden == false { return }
        if let pollingService {
            Task {
                pushEnabled ? await pollingService.stopRefreshing() : await pollingService.startRefreshing()
            }
        }
        pushDisabledNotificationView.hide(pushEnabled)
    }

    public func reachable(pushEnabled: Bool) {
        pushDisabledNotificationView.hide(pushEnabled)
        offlineNotificationView.hide()
        composeView.isEnabled = true
        suggestionsView.isEnabled = true
    }

    public func unreachable(isCachingEnabled: Bool) {
        pushDisabledNotificationView.hide()
        offlineNotificationView.show()
        composeView.isEnabled = isCachingEnabled
        suggestionsView.isEnabled = isCachingEnabled
    }
}

// MARK: UITableViewDataSource
extension ParleyView: UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        return messagesStore?.numberOfSections ?? .zero
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messagesStore?.numberOfRows(inSection: section) ?? .zero
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cellKind = messagesStore[indexPath: indexPath] else { return .init() }
        
        switch cellKind {
        case .loading:
            let loadingTableViewCell = tableView
                .dequeueReusableCell(withIdentifier: LoadingTableViewCell.reuseIdentifier) as! LoadingTableViewCell
            loadingTableViewCell.appearance = appearance.loading

            return loadingTableViewCell
        case .message(let message), .carousel(mainMessage: let message, _):
            let messageTableViewCell = tableView
                .dequeueReusableCell(withIdentifier: MessageTableViewCell.reuseIdentifier) as! MessageTableViewCell
            messageTableViewCell.delegate = self
            
            switch message.type {
            case .agent, .systemMessageAgent:
                messageTableViewCell.appearance = appearance.agentMessage
            default:
                messageTableViewCell.appearance = appearance.userMessage
            }
                
            messageTableViewCell.render(message, mediaLoader: mediaLoader, shareManager: shareManager)
            
            return messageTableViewCell
        case .typingIndicator:
            let agentTypingTableViewCell = tableView
                .dequeueReusableCell(
                    withIdentifier: AgentTypingTableViewCell
                        .reuseIdentifier
                ) as! AgentTypingTableViewCell
            agentTypingTableViewCell.appearance = appearance.typingBalloon

            return agentTypingTableViewCell
        case .info(let text):
            let infoTableViewCell = tableView
                .dequeueReusableCell(withIdentifier: InfoTableViewCell.reuseIdentifier) as! InfoTableViewCell
            infoTableViewCell.appearance = appearance.info
            infoTableViewCell.render(text)

            return infoTableViewCell
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard
            let sectionKind = messagesStore[section: section],
            case let MessagesStore.SectionKind.messages(date) = sectionKind
        else { return nil }
        
        return DateHeaderView(appearance: appearance.date, date: date)
    }
    
    public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        guard
            let sectionKind = messagesStore[section: section],
            case MessagesStore.SectionKind.messages = sectionKind
        else { return .zero }
        
        return DateHeaderView.estimatedHeight
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let cell = messagesStore[indexPath: indexPath] else { return .zero }
        switch cell {
        case .loading, .typingIndicator, .info:
            return UITableView.automaticDimension
        case .message(let message), .carousel(mainMessage: let message, carousel: _):
            return message.ignore() ? 0 : UITableView.automaticDimension
        }
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let loadingTableViewCell = cell as? LoadingTableViewCell {
            loadingTableViewCell.startAnimating()
        }

        if let agentTypingTableViewCell = cell as? AgentTypingTableViewCell {
            agentTypingTableViewCell.startAnimating()
        }
    }

    public func tableView(
        _ tableView: UITableView,
        didEndDisplaying cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        if let loadingTableViewCell = cell as? LoadingTableViewCell {
            loadingTableViewCell.stopAnimating()
        }

        if let agentTypingTableViewCell = cell as? AgentTypingTableViewCell {
            agentTypingTableViewCell.stopAnimating()
        }
    }
}

// MARK: UITableViewDelegate
extension ParleyView: UITableViewDelegate {

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        messagesTableView.scrollViewDidScroll()

        let height = scrollView.frame.height
        let scrollY = scrollView.contentOffset.y

        if scrollY < height / 2 {
            guard !isAlreadyAtTop else { return }
            isAlreadyAtTop = true
            Task {
                await messagesInteractor?.handleLoadMessages()
            }
        } else {
            isAlreadyAtTop = false
        }
        
        Task {
            await messagesInteractor?.setScrolledToBottom(messagesTableView.isAtBottom)
        }

        updateSuggestionsAlpha()
    }

    private func updateSuggestionsAlpha() {
        let scrollY = messagesTableView.contentOffset.y
        let contentHeight = messagesTableView.contentSize.height - messagesTableView.frame.size.height

        if messagesTableView.isAtBottom {
            let bottomSpace: CGFloat = switch appearance.notificationsPosition {
            case .top:
                0
            case .bottom:
                getNotificationsHeight()
            }
            let alpha = (scrollY - (contentHeight + bottomSpace)) / getSuggestionsHeight()
            suggestionsView.alpha = alpha
        } else {
            suggestionsView.alpha = 0
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        messagesTableView.deselectRow(at: indexPath, animated: false)
        if
            var message = messagesStore.getMessage(at: indexPath),
            message.status == .failed,
            message.type == .user
        {
            Task {
                await parley.send(&message, isNewMessage: false)
            }
        }
    }
}

// MARK: ParleyComposeViewDelegate
extension ParleyView: ParleyComposeViewDelegate {

    func failedToSelectImage() {
        let title = ParleyLocalizationKey.sendFailedTitle.localized()
        let message = ParleyLocalizationKey.sendFailedBodySelectingImage.localized()
        presentInformationalAlert(title: title, message: message)
    }

    @MainActor
    private func presentInformationalAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okMessage = ParleyLocalizationKey.ok.localized()
        alert.addAction(UIAlertAction(title: okMessage, style: .default))
        present(alert, animated: true)
    }

    func didChange() {
        if !composeView.textView.text.isEmpty {
            Task {
                await parley.userStartTyping()
            }
        }
    }

    func send(_ message: String) {
        Task {
            await parley.send(message, silent: false)
        }
    }

    func send(image: UIImage, with data: Data, url: URL) {
        Task { @MainActor in
            guard let mediaModel = MediaModel(image: image, data: data, url: url) else {
                presentInvalidMediaAlert() ; return
            }

            guard !mediaModel.isLargerThan(size: Self.maximumImageSizeInMegabytes) else {
                let title = ParleyLocalizationKey.sendFailedTitle.localized()
                let message = ParleyLocalizationKey.sendFailedBodyMediaTooLarge.localized()
                presentInformationalAlert(title: title, message: message)
                return
            }

            await send(media: mediaModel)
        }
    }

    @available(iOS 14.0, *)
    func send(image: UIImage, data: Data, fileName: String, type: UTType) {
        Task { @MainActor in
            guard let mediaModel = MediaModel(image: image, data: data, fileName: fileName, type: type) else {
                presentInvalidMediaAlert() ; return
            }

            await send(media: mediaModel)
        }
    }

    func send(file url: URL) {
        Task { @MainActor in
            guard let fileData = FileManager.default.contents(atPath: url.path) else {
                presentInvalidMediaAlert()
                return
            }

            let mediaModel = MediaModel(data: fileData, url: url)
            await send(media: mediaModel)
        }
    }

    @MainActor
    private func send(media: MediaModel) async {
        guard !media.isLargerThan(size: Self.maximumImageSizeInMegabytes) else {
            presentImageToLargeAlert() ; return
        }

        await parley.sendNewMessageWithMedia(media)
    }

    @MainActor
    private func presentInvalidMediaAlert() {
        let title = ParleyLocalizationKey.sendFailedTitle.localized()
        let message = ParleyLocalizationKey.sendFailedBodyMediaInvalid.localized()
        presentInformationalAlert(title: title, message: message)
    }

    @MainActor
    private func presentImageToLargeAlert() {
        let title = ParleyLocalizationKey.sendFailedTitle.localized()
        let message = ParleyLocalizationKey.sendFailedBodyMediaTooLarge.localized()
        presentInformationalAlert(title: title, message: message)
    }
}

// MARK: MessageTableViewCellDelegate
extension ParleyView: MessageTableViewCellDelegate {

    func didSelectMedia(_ media: MediaObject) {
        guard media.getMediaType().isImageType else {
            return
        }

        let imageViewController = MessageImageViewController(
            messageMedia: media,
            mediaLoader: mediaLoader
        )

        imageViewController.modalPresentationStyle = .overFullScreen
        imageViewController.modalTransitionStyle = .crossDissolve

        present(imageViewController, animated: true, completion: nil)
    }

    func shareMedia(url: URL) {
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
    }

    func didSelect(_ button: MessageButton) {
        guard let payload = button.payload else { return }
        switch button.type {
        case .phoneNumber:
            guard let url = URL(string: "tel://\(payload)") else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        case .webUrl:
            guard let url = URL(string: payload) else { return }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        case .reply:
            Task {
                await parley.send(payload, silent: false)
            }
        }
    }
}

// MARK: ParleySuggestionsViewDelegate
extension ParleyView: ParleySuggestionsViewDelegate {

    func didSelect(_ suggestion: String) {
        Task {
            await parley.send(suggestion, silent: false)
        }
    }
}

// MARK: - Accessibility
extension ParleyView {

    // MARK: VoiceOver
    override func voiceOverDidChange(isVoiceOverRunning: Bool) {
        reloadMessages()
    }

    // MARK: Dynamic Type
    @objc
    private func contentSizeCategoryDidChange() {
        reloadMessages()
    }
}

@MainActor
extension ParleyView: ParleyMessagesDisplay {
        
    func insertRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        messagesTableView.beginUpdates()
        for newSection in convertToIndexSet(indexPaths) {
            messagesTableView.insertSections(newSection, with: animation)
        }
        messagesTableView.insertRows(at: indexPaths, with: animation)
        messagesTableView.endUpdates()
    }
    
    func deleteRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        messagesTableView.beginUpdates()
        for oldSection in convertToIndexSet(indexPaths) {
            messagesTableView.deleteSections(oldSection, with: animation)
        }
        messagesTableView.deleteRows(at: indexPaths, with: animation)
        messagesTableView.endUpdates()
    }
    
    private func convertToIndexSet(_ indexPaths: [IndexPath]) -> [IndexSet] {
        indexPaths
            .filter({ $0.row == .zero })
            .map(\.section)
            .map(IndexSet.init(integer:))
    }
    
    func reloadRows(at indexPaths: [IndexPath], with animation: UITableView.RowAnimation) {
        messagesTableView.reloadRows(at: indexPaths, with: animation)
    }
    
    func scrollTo(indexPaths: IndexPath, at position: UITableView.ScrollPosition, animated: Bool) {
        messagesTableView.scrollToRow(at: indexPaths, at: position, animated: true)
    }
    
    func displayScrollToBottom(animated: Bool) {
        messagesTableView.scroll(to: .bottom, animated: animated)
    }
    
    func reload() {
        reloadMessages()
    }
    
    func display(quickReplies: [String]) {
        if UIAccessibility.isVoiceOverRunning {
            messagesTableView.scroll(to: .bottom, animated: false)
        }
        suggestionsView.isHidden = false
        suggestionsView.render(quickReplies)
    }
    
    func displayHideQuickReplies() {
        suggestionsView.render([])
        suggestionsView.isHidden = true
    }
    
    func display(stickyMessage: String) {
        stickyView.text = stickyMessage
        stickyView.isHidden = false
    }
    
    func displayHideStickyMessage() {
        stickyView.text = .none
        stickyView.isHidden = true
    }
}

extension ParleyView: @preconcurrency ParleySuggestionsView.BoundsDelegate {
    
    func boundsDidChange(
        for suggestionsView: ParleySuggestionsView,
        change: NSKeyValueObservedChange<CGRect>
    ) {
        syncMessageTableViewContentInsets()
    }
}

extension ParleyView: @preconcurrency ObservableStackView.BoundsDelegate {
    
    func boundsDidChange(
        for stackView: ObservableStackView,
        change: NSKeyValueObservedChange<CGRect>
    ) {
        syncMessageTableViewContentInsets()
    }
}
