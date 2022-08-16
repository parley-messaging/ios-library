import UIKit

public class ParleyView: UIView {

    @IBOutlet var contentView: UIView! {
        didSet {
            contentView.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet weak var messagesTableView: ReversedTableView! {
        didSet { messagesTableView.separatorStyle = .none }
    }

    @IBOutlet weak var notificationsStackView: UIStackView!
    @IBOutlet weak var notificationsConstraintTop: NSLayoutConstraint!
    private weak var notificationsConstraintBottom: NSLayoutConstraint? = nil
    @IBOutlet weak var pushDisabledNotificationView: ParleyNotificationView! {
        didSet {
            pushDisabledNotificationView.text = NSLocalizedString("parley_push_disabled", bundle: Bundle.current, comment: "")
        }
    }
    @IBOutlet weak var offlineNotificationView: ParleyNotificationView! {
        didSet {
            offlineNotificationView.text = NSLocalizedString("parley_notification_offline", bundle: Bundle.current, comment: "")
        }
    }
    @IBOutlet weak var stickyView: ParleyStickyView!
    
    @IBOutlet weak var suggestionsView: ParleySuggestionsView! {
        didSet {
            suggestionsView.delegate = self
            
            syncMessageTableViewContentInsets()
        }
    }
    @IBOutlet weak var suggestionsContraintBottom: NSLayoutConstraint!

    @IBOutlet weak var composeView: ParleyComposeView! {
        didSet{
            composeView.placeholder = NSLocalizedString("parley_type_message", bundle: Bundle.current, comment: "")
            composeView.maxCount = kParleyMessageMaxCount

            composeView.delegate = self
        }
    }

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    private let notificationService = NotificationService()
    private var pollingService: PollingServiceProtocol = PollingService()

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

    public var delegate: ParleyViewDelegate?

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
    }
    
    private func setupPollingIfNecessary() {
        pollingService.delegate = self
        notificationService.notificationsEnabled() { [pollingService] isEnabled in
            guard !isEnabled else { return }
            pollingService.startRefreshing()
        }
    }

    private func loadXib() {
        Bundle.current.loadNibNamed("ParleyView", owner: self, options: nil)

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
    }

    private func registerNibCell(_ nibName: String) {
        let tableViewCellNib = UINib(nibName: nibName, bundle: Bundle.current)
        messagesTableView.register(tableViewCellNib, forCellReuseIdentifier: nibName)
    }

    private func syncStackView(_ changes: @escaping () -> Void) {
        changes()
        
        notificationsStackView.isHidden = !notificationsStackView.arrangedSubviews.contains { view -> Bool in return view.isHidden == false }
        
        // Force redraw: otherwise `stackView.frame.height` is incorrect
        notificationsStackView.setNeedsLayout() // Require redraw
        notificationsStackView.layoutIfNeeded() // Execute redraw

        syncMessageTableViewContentInsets()
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
            suggestionsContraintBottom.constant = 0
        case .bottom:
            top = 0
            bottom = suggestionsHeight + notificationsHeight
            suggestionsContraintBottom.constant = notificationsHeight
        }
        
        messagesTableView.contentInset = UIEdgeInsets(
            top: top,
            left: 0,
            bottom: bottom,
            right: 0
        )

        let isAtBottom = self.messagesTableView.contentOffset.y <= 0
        if (isAtBottom) {
            // Stay at bottom
            self.messagesTableView.setContentOffset(CGPoint(x: 0, y: 0 - bottom), animated: true)
        }
    }
    
    private func getNotificationsHeight() -> CGFloat {
        return notificationsStackView.isHidden ? 0 : notificationsStackView.frame.height
    }
    
    private func getSuggestionsHeight() -> CGFloat {
        return suggestionsView.isHidden ? 0 : suggestionsView.frame.height
    }
    
    private func syncSuggestionsView() {
        if let message = getMessagesManager().messages.first, let quickReplies = message.quickReplies, !quickReplies.isEmpty {
            suggestionsView.isHidden = false
            
            suggestionsView.render(quickReplies)
        } else {
            suggestionsView.render([])
            
            suggestionsView.isHidden = true
        }
        
        // Force redraw: otherwise `stackView.frame.height` is incorrect
        suggestionsView.setNeedsLayout() // Require redraw
        suggestionsView.layoutIfNeeded() // Execute redraw
        
        syncStackView { }
    }

    // MARK: Observers
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillShowNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillHideNotification)
        NotificationCenter.default.removeObserver(UIDevice.orientationDidChangeNotification)
    }

    // MARK: Keyboard
    @objc private func keyboardDidShow(notification: NSNotification) {
        messagesTableView.addGestureRecognizer(tapGestureRecognizer)
    }

    @objc private func keyboardDidHide(notification: NSNotification) {
        messagesTableView.removeGestureRecognizer(tapGestureRecognizer)
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
                syncStackView { }
            }
            break;
        case .bottom:
            notificationsConstraintTop?.isActive = false
            notificationsConstraintBottom = notificationsStackView.bottomAnchor.constraint(equalTo: composeView.topAnchor, constant: 0)
            notificationsConstraintBottom?.isActive = true
            syncStackView { }
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

            statusLabel.text = NSLocalizedString("parley_state_unconfigured", bundle: Bundle.current, comment: "")
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

            statusLabel.text = NSLocalizedString("parley_state_failed", bundle: Bundle.current, comment: "")
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
            
            syncStackView { [weak self, messagesManager = getMessagesManager()] in
                self?.stickyView.text = messagesManager.stickyMessage
                self?.stickyView.isHidden = messagesManager.stickyMessage == nil
            }

            messagesTableView.reloadData()
            
            syncSuggestionsView()
            
            messagesTableView.scroll(to: .bottom, animated: false)
        }
    }

    func didChangePushEnabled(_ pushEnabled: Bool) {
        DispatchQueue.main.async { [weak self, pollingService] in
            if self?.offlineNotificationView.isHidden == false { return }
            pushEnabled ? pollingService.stopRefreshing() : pollingService.startRefreshing()
            
            self?.syncStackView { [weak self] in
                self?.pushDisabledNotificationView.isHidden = pushEnabled
            }
        }
    }

    func reachable() {
        syncStackView { [weak self] in
            self?.pushDisabledNotificationView.isHidden = Parley.shared.pushEnabled
            self?.offlineNotificationView.isHidden = true
        }

        composeView.isEnabled = true
        suggestionsView.isEnabled = true
    }

    func unreachable() {
        syncStackView { [weak self] in
            self?.pushDisabledNotificationView.isHidden = true
            self?.offlineNotificationView.isHidden = false
        }

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
        if indexPath.row >= getMessagesManager().messages.count {
            return .init()
        }
        
        let message = getMessagesManager().messages[indexPath.row]

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
        let height = scrollView.frame.height
        let scrollY = scrollView.contentOffset.y

        let contentHeight = scrollView.contentSize.height
        let insetHeight = scrollView.contentInset.top + scrollView.contentInset.bottom

        let position = Int(scrollY + height)
        let positionTop = Int(contentHeight + insetHeight)
        if positionTop-5...positionTop+5 ~= position, let lastMessageId = getMessagesManager().originalMessages.last?.id {
            Parley.shared.loadMoreMessages(lastMessageId)
        }
        
        if scrollY > 0 {
            suggestionsView.alpha = 0
        } else if scrollY < 0 {
            let bottomSpace: CGFloat
            switch appearance.notificationsPosition {
            case .top:
                bottomSpace = 0
            case .bottom:
                bottomSpace = getNotificationsHeight()
            }
            let alpha = (abs(scrollY) - bottomSpace) / getSuggestionsHeight()
            
            suggestionsView.alpha = alpha > 1 ? 1 : alpha
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        messagesTableView.deselectRow(at: indexPath, animated: false)

        let message = getMessagesManager().messages[indexPath.row]
        if message.status == .failed && message.type == .user {
            Parley.shared.send(message, isNewMessage: false)
        }
    }
}

// MARK: ParleyComposeViewDelegate
extension ParleyView: ParleyComposeViewDelegate {

    func didChange() {
        if !composeView.textView.text.isEmpty {
            Parley.shared.userStartTyping()
        }
    }

    func send(_ message: String) {
        Parley.shared.send(message)
    }
    
    func send(image: UIImage, with data: Data, url: URL, fileName: String) {
        Parley.shared.network.apiVersion.isUsingMedia
            ?  Parley.shared.upload(media: MediaModel(image: data, url: url, filename: fileName), displayedImage: image)
            :  Parley.shared.send(url, image, data)
    }
}

// MARK: MessageTableViewCellDelegate
extension ParleyView: MessageTableViewCellDelegate {
    
    func didSelectImage(from message: Message) {
        let imageViewController = MessageImageViewController()
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
            Parley.send(payload)
        case .none:
            break
        }
    }
}

// MARK: ParleySuggestionsViewDelegate
extension ParleyView: ParleySuggestionsViewDelegate {
    
    func didSelect(_ suggestion: String) {
        Parley.shared.send(suggestion)
    }
}
