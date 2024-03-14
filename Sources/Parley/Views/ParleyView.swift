import UIKit

public class ParleyView: UIView {

    @IBOutlet var contentView: UIView! {
        didSet {
            contentView.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    private var tableViewTopPaddingTapGestureRecognizer: UITapGestureRecognizer?

    private var messagesContentHeightObserver: NSKeyValueObservation?
    @IBOutlet private weak var messagesTableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var messagesTableView: MessagesTableView!
    @IBOutlet private weak var messagesTableViewPaddingToSafeAreaTopView: UIView!
    
    @IBOutlet weak var notificationsStackView: UIStackView!
    @IBOutlet weak var notificationsConstraintTop: NSLayoutConstraint!
    private weak var notificationsConstraintBottom: NSLayoutConstraint?
    @IBOutlet weak var pushDisabledNotificationView: ParleyNotificationView! {
        didSet {
            pushDisabledNotificationView.text = "parley_push_disabled".localized
        }
    }
    @IBOutlet weak var offlineNotificationView: ParleyNotificationView! {
        didSet {
            offlineNotificationView.text = "parley_notification_offline".localized
        }
    }
    @IBOutlet weak var stickyView: ParleyStickyView!
    
    @IBOutlet weak var suggestionsView: ParleySuggestionsView! {
        didSet {
            suggestionsView.delegate = self
            
            syncMessageTableViewContentInsets()
        }
    }
    @IBOutlet weak var suggestionsConstraintBottom: NSLayoutConstraint!

    @IBOutlet weak var composeView: ParleyComposeView! {
        didSet {
            composeView.placeholder = "parley_type_message".localized
            composeView.maxCount = kParleyMessageMaxCount

            composeView.delegate = self
        }
    }

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    private let notificationService = NotificationService()
    private var messageRepository: MessageRepository = MessageRepository(remote: Parley.shared.remote)
    private var pollingService: PollingServiceProtocol = PollingService()
    
    private var observeNotificationsBounds: NSKeyValueObservation?
    private var observeSuggestionsBounds: NSKeyValueObservation?
    private var isShowingKeyboardWithMessagesScrolledToBottom = false
    private var isAlreadyAtTop = false

    public var appearance = ParleyViewAppearance() {
        didSet {
            apply(appearance)
        }
    }

    public var imagesEnabled = true {
        didSet {
            composeView.allowPhotos = imagesEnabled
        }
    }

    public weak var delegate: ParleyViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    deinit {
        removeObservers()

        Parley.shared.delegate = nil
    }

    private func setup() {
        loadXib()

        apply(appearance)

        setupMessagesTableView()

        addObservers()

        Parley.shared.delegate = self
        
        setupPollingIfNecessary()
        
        observeNotificationsBounds = notificationsStackView.observe(\.bounds) { [weak self] _, _ in
            self?.syncMessageTableViewContentInsets()
        }
        observeSuggestionsBounds = suggestionsView.observe(\.bounds) { [weak self] _, _ in
            self?.syncMessageTableViewContentInsets()
        }
    }
    
    private func setupPollingIfNecessary() {
        pollingService.delegate = self
        notificationService.notificationsEnabled() { [weak self] isEnabled in
            guard !isEnabled else { return }
            self?.pollingService.startRefreshing()
        }
    }

    private func loadXib() {
        Bundle.module.loadNibNamed("ParleyView", owner: self, options: nil)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }

    private func getMessagesManager() -> MessagesManager {
        return Parley.shared.messagesManager
    }

    // MARK: Views
    private func setupMessagesTableView() {
        let cellIdentifiers = [
            "InfoTableViewCell",
            "DateTableViewCell",
            "LoadingTableViewCell",
            
            "MessageTableViewCell",
            "AgentTypingTableViewCell",
        ]

        cellIdentifiers.forEach { cellIdentifier in
            registerNibCell(cellIdentifier)
        }

        messagesTableView.dataSource = self
        messagesTableView.delegate = self
        messagesTableView.separatorStyle = .none
        messagesTableView.keyboardDismissMode = .interactive
        messagesTableView.alwaysBounceVertical = false
        
        messagesContentHeightObserver = messagesTableView.observe(\.contentSize, options: [.initial, .new]) { [weak self] messagesTableView, change in
            guard let self, let newContentHeight = change.newValue?.height else { return }
            let verticalInsets = messagesTableView.contentInset.top + messagesTableView.contentInset.bottom
            let newHeight = newContentHeight + verticalInsets
            
            self.messagesTableViewHeightConstraint.constant = newHeight
            
            let isScrollable = newContentHeight > messagesTableView.frame.maxY
            if isScrollable {
                messagesTableView.keyboardDismissMode = .interactive
            } else {
                messagesTableView.keyboardDismissMode = .onDrag
            }
            updateSuggestionsAlpha()
        }
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
        return notificationsStackView.frame.height
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
        return suggestionsView.isHidden ? 0 : suggestionsView.frame.height
    }
    
    private func syncSuggestionsView() {
        if let message = getMessagesManager().messages.last, let quickReplies = message.quickReplies, !quickReplies.isEmpty {
            if UIAccessibility.isVoiceOverRunning {
                messagesTableView.scroll(to: .bottom, animated: false)
            }
            suggestionsView.isHidden = false
            suggestionsView.render(quickReplies)
        } else {
            suggestionsView.render([])
            suggestionsView.isHidden = true
        }
    }

    // MARK: Observers
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardDidHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
        watchForVoiceOverDidChangeNotification(observer: self)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillShowNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardDidShowNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillHideNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardDidHideNotification)
        NotificationCenter.default.removeObserver(UIDevice.orientationDidChangeNotification)
        NotificationCenter.default.removeObserver(UIContentSizeCategory.didChangeNotification)
        NotificationCenter.default.removeObserver(UIAccessibility.voiceOverStatusDidChangeNotification)
    }

    // MARK: Keyboard
    @objc private func keyboardWillShow(notification: NSNotification) {
        messagesTableView.addGestureRecognizer(tapGestureRecognizer)
        
        if messagesTableView.isAtBottom {
            isShowingKeyboardWithMessagesScrolledToBottom = true
        }
        
        let topPaddingTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard(_:)))
        messagesTableViewPaddingToSafeAreaTopView.addGestureRecognizer(topPaddingTapGestureRecognizer)
        tableViewTopPaddingTapGestureRecognizer = topPaddingTapGestureRecognizer
    }
    
    @objc private func keyboardDidShow() {
        guard isShowingKeyboardWithMessagesScrolledToBottom else { return }
        messagesTableView.scroll(to: .bottom, animated: false)
        isShowingKeyboardWithMessagesScrolledToBottom = false
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        messagesTableView.removeGestureRecognizer(tapGestureRecognizer)
        if let tableViewTopPaddingTapGestureRecognizer {
            messagesTableViewPaddingToSafeAreaTopView.removeGestureRecognizer(tableViewTopPaddingTapGestureRecognizer)
            self.tableViewTopPaddingTapGestureRecognizer = nil
        }
        
        if messagesTableView.isAtBottom {
            isShowingKeyboardWithMessagesScrolledToBottom = true
        }
    }
    
    @objc private func keyboardDidHide() {
        guard isShowingKeyboardWithMessagesScrolledToBottom else { return }
        messagesTableView.scroll(to: .bottom, animated: true)
        isShowingKeyboardWithMessagesScrolledToBottom = false
    }

    @IBAction func hideKeyboard(_ sender: Any) {
        endEditing(true)
    }
    
    // MARK: Orientation
    @objc private func orientationDidChange() {
        messagesTableView.reloadData()
    }

    // MARK: Appearance
    private func apply(_ appearance: ParleyViewAppearance) {
        backgroundColor = appearance.backgroundColor

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
            break;
        case .bottom:
            notificationsConstraintTop?.isActive = false
            notificationsConstraintBottom = notificationsStackView.bottomAnchor.constraint(equalTo: composeView.topAnchor, constant: 0)
            notificationsConstraintBottom?.isActive = true
            break;
        }
        messagesTableView.reloadData()
    }
}

// MARK: ParleyDelegate
extension ParleyView: ParleyDelegate {

    func willSend(_ indexPaths: [IndexPath]) {
        syncSuggestionsView()
        
        messagesTableView.insertRows(at: indexPaths, with: .none)
        messagesTableView.scroll(to: .bottom, animated: false)
    }

    func didUpdate(_ message: Message) {
        if let index = getMessagesManager().messages.firstIndex(of: message) {
            messagesTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }

    func didSent(_ message: Message) {
        delegate?.didSentMessage()
        UIAccessibility.post(notification: .announcement, argument: "parley_voice_over_announcement_sent_message".localized)
    }

    func didReceiveMessage(_ indexPath: [IndexPath]) {
        syncSuggestionsView()
        
        messagesTableView.insertRows(at: indexPath, with: .none)
        messagesTableView.scroll(to: .bottom, animated: false)
    }

    func didReceiveMessages() {
        syncSuggestionsView()
        
        messagesTableView.reloadData()
    }

    func didStartTyping() {
        let indexPaths = getMessagesManager().addTypingMessage()
        messagesTableView.insertRows(at: indexPaths, with: .none)

        messagesTableView.scroll(to: .bottom, animated: false)
    }

    func didStopTyping() {
        if let indexPaths = getMessagesManager().removeTypingMessage() {
            messagesTableView.deleteRows(at: indexPaths, with: .none)

            messagesTableView.scroll(to: .bottom, animated: false)
        }
    }

    func didChangeState(_ state: Parley.State) {
        debugPrint("ParleyViewDelegate.didChangeState:: \(state)")

        switch state {
        case .unconfigured:
            messagesTableView.reloadData()
            messagesTableView.isHidden = true
            composeView.isHidden = true
            suggestionsView.isHidden = true

            statusLabel.text = "parley_state_unconfigured".localized
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

            statusLabel.text = "parley_state_failed".localized
            statusLabel.isHidden = false

            activityIndicatorView.isHidden = true
            activityIndicatorView.stopAnimating()

            stickyView.isHidden = true
        case .configured:
            messagesTableView.isHidden = false
            composeView.isHidden = false
            statusLabel.isHidden = true

            activityIndicatorView.isHidden = true
            activityIndicatorView.stopAnimating()
            
            stickyView.text = getMessagesManager().stickyMessage
            stickyView.isHidden = getMessagesManager().stickyMessage == nil

            messagesTableView.reloadData()
            
            syncSuggestionsView()
            
            messagesTableView.scroll(to: .bottom, animated: false)
            
            DispatchQueue.main.async { [weak self] in
                self?.messagesTableView.scroll(to: .bottom, animated: false)
                self?.updateSuggestionsAlpha() // For VoiceOver
            }
        }
    }

    func didChangePushEnabled(_ pushEnabled: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let pollingService = self?.pollingService else { return }
            if self?.offlineNotificationView.isHidden == false { return }
            pushEnabled ? pollingService.stopRefreshing() : pollingService.startRefreshing()
            
            self?.pushDisabledNotificationView.isHidden = pushEnabled
        }
    }

    func reachable() {
        pushDisabledNotificationView.isHidden = Parley.shared.pushEnabled
        offlineNotificationView.isHidden = true

        composeView.isEnabled = true
        suggestionsView.isEnabled = true
    }

    func unreachable() {
        pushDisabledNotificationView.isHidden = true
        offlineNotificationView.isHidden = false

        composeView.isEnabled = Parley.shared.isCachingEnabled()
        suggestionsView.isEnabled = Parley.shared.isCachingEnabled()
    }
}

// MARK: UITableViewDataSource
extension ParleyView: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getMessagesManager().messages.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let message = getMessagesManager().messages[safe: indexPath.row] else { return .init() }

        switch message.type {
        case .agent?:
            let messageTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell") as! MessageTableViewCell
            messageTableViewCell.delegate = self
            messageTableViewCell.appearance = appearance.agentMessage
            messageTableViewCell.render(message)

            return messageTableViewCell
        case .date?:
            let dateTableViewCell = tableView.dequeueReusableCell(withIdentifier: "DateTableViewCell") as! DateTableViewCell
            dateTableViewCell.appearance = appearance.date
            dateTableViewCell.render(message)

            return dateTableViewCell
        case .info?:
            let infoTableViewCell = tableView.dequeueReusableCell(withIdentifier: "InfoTableViewCell") as! InfoTableViewCell
            infoTableViewCell.appearance = appearance.info
            infoTableViewCell.render(message)

            return infoTableViewCell
        case .loading?:
            let loadingTableViewCell = tableView.dequeueReusableCell(withIdentifier: "LoadingTableViewCell") as! LoadingTableViewCell
            loadingTableViewCell.appearance = appearance.loading

            return loadingTableViewCell
        case .agentTyping?:
            let agentTypingTableViewCell = tableView.dequeueReusableCell(withIdentifier: "AgentTypingTableViewCell") as! AgentTypingTableViewCell
            agentTypingTableViewCell.appearance = appearance.typingBalloon

            return agentTypingTableViewCell
        case .user?:
            let messageTableViewCell = tableView.dequeueReusableCell(withIdentifier: "MessageTableViewCell") as! MessageTableViewCell
            messageTableViewCell.delegate = self
            messageTableViewCell.appearance = appearance.userMessage
            messageTableViewCell.render(message)

            return messageTableViewCell
        default:
            return .init()
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row >= getMessagesManager().messages.count {
            return 0
        }
        let message = getMessagesManager().messages[indexPath.row]

        if message.ignore() {
            return 0
        } else {
            return UITableView.automaticDimension
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

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
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
            guard 
                !isAlreadyAtTop,
                let lastMessageId = getMessagesManager().getOldestMessage()?.id
            else { return }
            
            isAlreadyAtTop = true
            Parley.shared.loadMoreMessages(lastMessageId)
        } else {
            isAlreadyAtTop = false
        }
        
        updateSuggestionsAlpha()
    }
    
    private func updateSuggestionsAlpha() {
        let scrollY = messagesTableView.contentOffset.y
        let contentHeight = messagesTableView.contentSize.height - messagesTableView.frame.size.height
        
        if messagesTableView.isAtBottom {
            let bottomSpace: CGFloat
            switch appearance.notificationsPosition {
            case .top:
                bottomSpace = 0
            case .bottom:
                bottomSpace = getNotificationsHeight()
            }
            let alpha = (scrollY - (contentHeight + bottomSpace)) / getSuggestionsHeight()
            suggestionsView.alpha = alpha
        } else {
            suggestionsView.alpha = 0
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        messagesTableView.deselectRow(at: indexPath, animated: false)

        let message = getMessagesManager().messages[indexPath.row]
        if message.status == .failed && message.type == .user {
            Task {
                await Parley.shared.send(message, isNewMessage: false)
            }
        }
    }
}

// MARK: ParleyComposeViewDelegate
extension ParleyView: ParleyComposeViewDelegate {
    
    func failedToSelectImage() {
        let title = "parley_send_failed_title".localized
        let message = "parley_send_failed_body_selecting_image".localized
        presentInformationalAlert(title: title, message: message)
    }
    
    @MainActor
    private func presentInformationalAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okMessage = "parley_ok".localized
        alert.addAction(UIAlertAction(title: okMessage, style: .default))
        present(alert, animated: true)
    }

    func didChange() {
        if !composeView.textView.text.isEmpty {
            Parley.shared.userStartTyping()
        }
    }

    func send(_ message: String) {
        Parley.shared.send(message)
    }
    
    func send(image: UIImage, with data: Data, url: URL) {
        Task { @MainActor in
            guard let mediaModel = MediaModel(image: image, data: data, url: url) else {
                let title = "parley_send_failed_title".localized
                let message = "parley_send_failed_body_media_invalid".localized
                presentInformationalAlert(title: title, message: message)
                return
            }
            
            guard !mediaModel.isLargerThan(size: 10) else {
                let title = "parley_send_failed_title".localized
                let message = "parley_send_failed_body_media_too_large".localized
                presentInformationalAlert(title: title, message: message)
                return
            }
            
            await Parley.shared.upload(media: mediaModel)
        }
    }
}

// MARK: MessageTableViewCellDelegate
extension ParleyView: MessageTableViewCellDelegate {
    
    func didSelectImage(from message: Message) {
        let imageViewController = MessageImageViewController(messageRepository: messageRepository)
        imageViewController.modalPresentationStyle = .overFullScreen
        imageViewController.modalTransitionStyle = .crossDissolve
        imageViewController.message = message

        present(imageViewController, animated: true, completion: nil)
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
            Parley.shared.send(payload)
        }
    }
}

// MARK: ParleySuggestionsViewDelegate
extension ParleyView: ParleySuggestionsViewDelegate {
    
    func didSelect(_ suggestion: String) {
        Parley.shared.send(suggestion)
    }
}

// MARK: - Accessibility
extension ParleyView {
    
    // MARK: VoiceOver
    override func voiceOverDidChange(isVoiceOverRunning: Bool) {
        messagesTableView.reloadData()
    }
    
    // MARK: Dynamic Type
    @objc private func contentSizeCategoryDidChange() {
        messagesTableView.reloadData()
    }
}
