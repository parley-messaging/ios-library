import UIKit

final class MessageImageViewController: UIViewController {
    
    private var scrollView = UIScrollView()
    private var imageView = UIImageView()
    private var activityIndicatorView = UIActivityIndicatorView()
    
    var message: Message?
    
    private let messageRepository: MessageRepository
    private lazy var imageLoader: ImageLoader = Parley.shared.imageLoader
    
    init(messageRepository: MessageRepository) {
        self.messageRepository = messageRepository
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupScrollView()
        setupImageView()
        setupActivityIndicatorView()
        
        addSwipeToDismissPanGestureRecognizer()
        
        addDismissButton()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let widthScale = 1 / self.imageView.frame.width * self.scrollView.bounds.width
        let heightScale = 1 / self.imageView.frame.height * self.scrollView.bounds.height
        
        let minimumScale = min(widthScale, heightScale)
        if minimumScale < 1 {
            self.scrollView.minimumZoomScale = minimumScale
            self.scrollView.zoomScale = minimumScale
        }
        self.scrollView.maximumZoomScale = minimumScale * 3
        
        self.adjustContentInset()
    }
    
    private func setupView() {
        self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
    }
    
    private func setupScrollView(){
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.showsVerticalScrollIndicator = false
        
        self.scrollView.delegate = self
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.scrollView)
        
        NSLayoutConstraint.activate([
            NSLayoutConstraint(item: self.scrollView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: self.scrollView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
        ])
    }
    
    private func setupImageView() {
        scrollView.addSubview(imageView)
        guard let mediaId = message?.media?.id else { 
            dismiss(animated: true, completion: nil) ; return
        }
        
        displayImageLoading()
        loadImage(id: mediaId)
    }
    
    private func displayImageLoading() {
        activityIndicatorView.startAnimating()
    }
    
    private func loadImage(id: String) {
        Task {
            do {
                let image = try await imageLoader.load(id: id)
                display(image: image.image)
            } catch {
                displayFailedLoadingImage()
            }
        }
    }
    
    @MainActor private func display(image: UIImage) {
        imageView.image = image
        imageView.sizeToFit()
        adjustContentInset()
        activityIndicatorView.stopAnimating()
    }
    
    @MainActor private func displayFailedLoadingImage() {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupActivityIndicatorView() {
        self.activityIndicatorView.style = .medium
        self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(self.activityIndicatorView)
        
        NSLayoutConstraint(item: self.activityIndicatorView, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0).isActive = true
        NSLayoutConstraint(item: self.activityIndicatorView, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0).isActive = true
    }
    
    private func adjustContentInset() {
        let imageViewSize = self.imageView.frame.size
        let scrollViewSize = self.scrollView.bounds.size
        
        let verticalInset = imageViewSize.height < scrollViewSize.height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalInset = imageViewSize.width < scrollViewSize.width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: horizontalInset, bottom: verticalInset, right: horizontalInset)
    }
    
    
    private func addDismissButton() {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "ic_close", in: .module, compatibleWith: .none)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.isAccessibilityElement = true
        button.accessibilityLabel = "parley_close".localized
        
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
        
        button.addTarget(self, action: #selector(dismissTapped), for: .touchUpInside)
    }
    
    @objc private func dismissTapped() {
        dismissWithSwipeToDismiss(1)
    }
    
    // MARK: Swipe to dismiss
    private func addSwipeToDismissPanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handleSwipeToDismiss))
        panGestureRecognizer.cancelsTouchesInView = false
        
        self.view.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func handleSwipeToDismiss(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let translation = panGestureRecognizer.translation(in: self.view)
        let translationY = translation.y
        let translationYAbsolute = abs(translationY)
        
        var frame = self.scrollView.frame
        frame.origin = CGPoint(x: 0, y: translationY)
        self.scrollView.frame = frame
        
        self.view.alpha = 1 - (translationYAbsolute / 300)
        
        if panGestureRecognizer.state == .ended {
            if translationYAbsolute > 100 {
                self.dismissWithSwipeToDismiss(translationY)
            } else {
                self.resetSwipeToDismiss()
            }
        }
    }
    
    private func dismissWithSwipeToDismiss(_ translationY: CGFloat) {
        UIView.animate(withDuration: 0.25, animations: {
            self.view.alpha = 0
            
            var frame = self.scrollView.frame
            frame.origin = CGPoint(x: 0, y: translationY > 0 ? self.view.frame.height : -self.view.frame.height)
            self.scrollView.frame = frame
        }) { _ in
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    private func resetSwipeToDismiss() {
        UIView.animate(withDuration: 0.25) {
            self.view.alpha = 1
            
            var frame = self.scrollView.frame
            frame.origin = CGPoint(x: 0, y: 0)
            self.scrollView.frame = frame
        }
    }
}

extension MessageImageViewController: UIScrollViewDelegate {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.adjustContentInset()
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
