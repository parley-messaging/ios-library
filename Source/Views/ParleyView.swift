import Reachability

public class ParleyView: UIView {

    @IBOutlet var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }

    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!

    @IBOutlet weak var messagesTableView: ReversedTableView! {
        didSet {
            self.messagesTableView.separatorStyle = .none
        }
    }

    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var pushDisabledNotificationView: ParleyNotificationView! {
        didSet {
            self.pushDisabledNotificationView.text = NSLocalizedString("parley_push_disabled", bundle: Bundle(for: type(of: self)), comment: "")
        }
    }
    @IBOutlet weak var offlineNotificationView: ParleyNotificationView! {
        didSet {
            self.offlineNotificationView.text = NSLocalizedString("parley_notification_offline", bundle: Bundle(for: type(of: self)), comment: "")
        }
    }
    @IBOutlet weak var stickyView: ParleyStickyView!
    
    @IBOutlet weak var suggestionsView: ParleySuggestionsView! {
        didSet {
            self.suggestionsView.delegate = self
            
            self.syncMessageTableViewContentInsets()
        }
    }

    @IBOutlet weak var composeView: ParleyComposeView! {
        didSet{
            self.composeView.placeholder = NSLocalizedString("parley_type_message", bundle: Bundle(for: type(of: self)), comment: "")
            self.composeView.maxCount = kParleyMessageMaxCount

            self.composeView.delegate = self
        }
    }

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!

    public var appearance = ParleyViewAppearance() {
        didSet {
            self.apply(self.appearance)
        }
    }

    public var imagesEnabled = true {
        didSet {
            self.composeView.allowPhotos = self.imagesEnabled
        }
    }

    public var delegate: ParleyViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.setup()
    }

    deinit {
        self.removeObservers()

        Parley.shared.delegate = nil
    }

    private func setup() {
        self.loadXib()

        self.apply(self.appearance)

        self.setupMessagesTableView()

        self.addObservers()

        Parley.shared.delegate = self
    }

    private func loadXib() {
        Bundle(for: type(of: self)).loadNibNamed("ParleyView", owner: self, options: nil)

        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)

        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
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

        self.messagesTableView.dataSource = self
        self.messagesTableView.delegate = self
    }

    private func registerNibCell(_ nibName: String) {
        let tableViewCellNib = UINib(nibName: nibName, bundle: Bundle(for: type(of: self)))
        self.messagesTableView.register(tableViewCellNib, forCellReuseIdentifier: nibName)
    }

    private func syncStackView(_ changes: @escaping () -> Void) {
        UIView.animate(withDuration: 0, animations: changes) { finished in
            if !finished { return }

            self.stackView.isHidden = !self.stackView.arrangedSubviews.contains { view -> Bool in return view.isHidden == false }
            
            self.syncMessageTableViewContentInsets()
        }
    }
    
    private func syncMessageTableViewContentInsets() {
        let top = self.stackView.isHidden ? 0 : self.stackView.frame.height
        let bottom = self.suggestionsView.isHidden ? 0 : self.suggestionsView.frame.height
        
        self.messagesTableView.contentInset = UIEdgeInsets(
            top: top,
            left: 0,
            bottom: bottom,
            right: 0
        )
    }
    
    private func syncSuggestionsView() {
        if let message = getMessagesManager().messages.first, let quickReplies = message.quickReplies, quickReplies.count > 0 {
            self.suggestionsView.render(quickReplies)
            
            self.suggestionsView.isHidden = false
            
            self.syncMessageTableViewContentInsets()
        } else {
            self.suggestionsView.render([])
            
            self.suggestionsView.isHidden = true
            
            self.syncMessageTableViewContentInsets()
        }
    }

    // MARK: Observers
    private func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillShowNotification)
        NotificationCenter.default.removeObserver(UIResponder.keyboardWillHideNotification)
        NotificationCenter.default.removeObserver(UIDevice.orientationDidChangeNotification)
    }

    // MARK: Keyboard
    @objc private func keyboardDidShow(notification: NSNotification) {
        self.messagesTableView.addGestureRecognizer(self.tapGestureRecognizer)
    }

    @objc private func keyboardDidHide(notification: NSNotification) {
        self.messagesTableView.removeGestureRecognizer(self.tapGestureRecognizer)
    }

    @IBAction func hideKeyboard(_ sender: Any) {
        self.endEditing(true)
    }
    
    // MARK: Orientation
    @objc private func orientationDidChange() {
        self.messagesTableView.reloadData()
    }

    // MARK: Appearance
    private func apply(_ appearance: ParleyViewAppearance) {
        self.backgroundColor = appearance.backgroundColor

        self.statusLabel.textColor = appearance.textColor

        self.pushDisabledNotificationView.appearance = appearance.pushDisabledNotification
        self.offlineNotificationView.appearance = appearance.offlineNotification
        self.stickyView.appearance = appearance.sticky
        self.composeView.appearance = appearance.compose
        
        self.suggestionsView.appearance = appearance.suggestions

        self.messagesTableView.reloadData()
    }
}

// MARK: ParleyDelegate
extension ParleyView: ParleyDelegate {

    func willSend(_ indexPaths: [IndexPath]) {
        self.syncSuggestionsView()
        
        self.messagesTableView.insertRows(at: indexPaths, with: .none)
        self.messagesTableView.scroll(to: .bottom, animated: false)
    }

    func didUpdate(_ message: Message) {
        if let index = getMessagesManager().messages.firstIndex(of: message) {
            self.messagesTableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
    }

    func didSent(_ message: Message) {
        self.delegate?.didSentMessage()
    }

    func didReceiveMessage(_ indexPath: [IndexPath]) {
        self.syncSuggestionsView()
        
        self.messagesTableView.insertRows(at: indexPath, with: .none)
        self.messagesTableView.scroll(to: .bottom, animated: false)
    }

    func didReceiveMessages() {
        self.syncSuggestionsView()
        
        self.messagesTableView.reloadData()
    }

    func didStartTyping() {
        let indexPaths = self.getMessagesManager().addTypingMessage()
        self.messagesTableView.insertRows(at: indexPaths, with: .none)

        self.messagesTableView.scroll(to: .bottom, animated: false)
    }

    func didStopTyping() {
        if let indexPaths = self.getMessagesManager().removeTypingMessage() {
            self.messagesTableView.deleteRows(at: indexPaths, with: .none)

            self.messagesTableView.scroll(to: .bottom, animated: false)
        }
    }

    func didChangeState(_ state: Parley.State) {
        debugPrint("ParleyViewDelegate.didChangeState:: \(state)")

        switch state {
        case .unconfigured:
            self.messagesTableView.isHidden = true
            self.composeView.isHidden = true
            self.suggestionsView.isHidden = true

            self.statusLabel.text = NSLocalizedString("parley_state_unconfigured", bundle: Bundle(for: type(of: self)), comment: "")
            self.statusLabel.isHidden = false

            self.activityIndicatorView.isHidden = true
            self.activityIndicatorView.stopAnimating()

            self.stickyView.isHidden = true

            break
        case .configuring:
            self.messagesTableView.isHidden = true
            self.composeView.isHidden = true
            self.statusLabel.isHidden = true
            self.suggestionsView.isHidden = true

            self.activityIndicatorView.isHidden = false
            self.activityIndicatorView.startAnimating()

            self.stickyView.isHidden = true

            break
        case .failed:
            self.messagesTableView.isHidden = true
            self.composeView.isHidden = true
            self.suggestionsView.isHidden = true

            self.statusLabel.text = NSLocalizedString("parley_state_failed", bundle: Bundle(for: type(of: self)), comment: "")
            self.statusLabel.isHidden = false

            self.activityIndicatorView.isHidden = true
            self.activityIndicatorView.stopAnimating()

            self.stickyView.isHidden = true

            break
        case .configured:
            self.messagesTableView.isHidden = false
            self.composeView.isHidden = false
            self.statusLabel.isHidden = true

            self.activityIndicatorView.isHidden = true
            self.activityIndicatorView.stopAnimating()

            self.stickyView.text = self.getMessagesManager().stickyMessage
            self.stickyView.isHidden = self.getMessagesManager().stickyMessage == nil

            self.messagesTableView.reloadData()
            
            self.syncSuggestionsView()
            
            self.messagesTableView.scroll(to: .bottom, animated: false)
        }
    }

    func didChangePushEnabled(_ pushEnabled: Bool) {
        DispatchQueue.main.async {
            if self.offlineNotificationView.isHidden == false { return }

            self.syncStackView {
                self.pushDisabledNotificationView.isHidden = pushEnabled
            }
        }
    }

    func reachable() {
        self.syncStackView {
            self.pushDisabledNotificationView.isHidden = Parley.shared.pushEnabled
            self.offlineNotificationView.isHidden = true
        }

        self.composeView.isEnabled = true
        self.suggestionsView.isEnabled = true
    }

    func unreachable() {
        self.syncStackView {
            self.pushDisabledNotificationView.isHidden = true
            self.offlineNotificationView.isHidden = false
        }

        self.composeView.isEnabled = Parley.shared.isCachingEnabled()
        self.suggestionsView.isEnabled = Parley.shared.isCachingEnabled()
    }
}

// MARK: UITableViewDataSource
extension ParleyView: UITableViewDataSource {

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getMessagesManager().messages.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
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
            self.suggestionsView.alpha = 0
        } else if scrollY < 0 {
            let alpha = abs(scrollY) / self.suggestionsView.frame.height
            
            self.suggestionsView.alpha = alpha > 1 ? 1 : alpha
        }
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.messagesTableView.deselectRow(at: indexPath, animated: false)

        let message = getMessagesManager().messages[indexPath.row]
        if message.status == .failed && message.type == .user {
            Parley.shared.send(message, isNewMessage: false)
        }
    }
}

// MARK: ParleyComposeViewDelegate
extension ParleyView: ParleyComposeViewDelegate {

    func didChange() {
        if !self.composeView.textView.text.isEmpty {
            Parley.shared.userStartTyping()
        }
    }

    func send(_ message: String) {
        Parley.shared.send(message)
    }

    func send(_ url: URL, _ image: UIImage, _ data: Data?=nil) {
        Parley.shared.send(url, image, data)
    }
}

// MARK: MessageTableViewCellDelegate
extension ParleyView: MessageTableViewCellDelegate {
    
    func didSelectImage(from message: Message) {
        let imageViewController = MessageImageViewController()
        imageViewController.modalPresentationStyle = .overFullScreen
        imageViewController.modalTransitionStyle = .crossDissolve
        imageViewController.message = message

        self.present(imageViewController, animated: true, completion: nil)
    }
    
    func didSelect(_ messageButton: MessageButton) {
        guard let url = URL(string: messageButton.payload) else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}

// MARK: ParleySuggestionsViewDelegate
extension ParleyView: ParleySuggestionsViewDelegate {
    
    func didSelect(_ suggestion: String) {
        Parley.shared.send(suggestion)
    }
}
