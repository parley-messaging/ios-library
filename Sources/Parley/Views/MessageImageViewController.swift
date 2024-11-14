import UIKit

final class MessageImageViewController: UIViewController {

    private var scrollView = UIScrollView()
    private var imageView = UIImageView()
    private let activityIndicatorView = UIActivityIndicatorView()
    private let dismissButton = UIButton()

    private let messageMedia: MediaObject
    private let mediaLoader: MediaLoaderProtocol

    init(
        messageMedia: MediaObject,
        mediaLoader: MediaLoaderProtocol
    ) {
        self.messageMedia = messageMedia
        self.mediaLoader = mediaLoader

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupScrollView()
        setupActivityIndicatorView()
        setupImageView()

        addSwipeToDismissPanGestureRecognizer()
        addDismissButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        loadImage(media: messageMedia)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        reconstructView(size: size)
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    private func reconstructView(size: CGSize) {
        scrollView.removeFromSuperview()
        scrollView = UIScrollView(frame: CGRect(x: .zero, y: .zero, width: size.width, height: size.height))
        
        let image = imageView.image
        imageView.removeFromSuperview()
        imageView = UIImageView()
        
        setupScrollView()
        setupImageView()
        
        view.bringSubviewToFront(dismissButton)
        
        if let image {
            display(image: image)
        } else {
            loadImage(media: messageMedia)
        }
    }

    private func setupView() {
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.75)
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        scrollView.delegate = self

        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupActivityIndicatorView() {
        view.addSubview(activityIndicatorView)

        activityIndicatorView.style = .medium
        activityIndicatorView.color = .white
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func setupImageView() {
        scrollView.addSubview(imageView)
    }

    private func startImageLoading() {
        activityIndicatorView.startAnimating()
    }

    @MainActor
    private func stopImageLoading() {
        activityIndicatorView.stopAnimating()
    }

    private func loadImage(media: MediaObject) {
        startImageLoading()

        Task {
            defer { stopImageLoading() }
            guard
                let mediaData = try? await mediaLoader.load(media: media),
                let image = media.imageFromData(mediaData) else
            {
                displayFailedLoadingImage()
                return
            }

            display(image: image)
        }
    }

    @MainActor
    private func display(image: UIImage) {
        imageView.image = image
        updateScale()
    }

    @MainActor
    private func displayFailedLoadingImage() {
        dismiss(animated: true, completion: nil)
    }

    private func updateScale() {
        imageView.sizeToFit()

        let widthScale = 1 / imageView.frame.width * scrollView.bounds.width
        let heightScale = 1 / imageView.frame.height * scrollView.bounds.height

        let minimumScale = min(widthScale, heightScale)
        if minimumScale < 1 {
            scrollView.minimumZoomScale = minimumScale
            scrollView.zoomScale = minimumScale
        }

        scrollView.maximumZoomScale = minimumScale * 3
        adjustContentInset()
    }

    private func adjustContentInset() {
        let imageViewSize = imageView.frame.size
        let scrollViewSize = scrollView.bounds.size

        let verticalInset = imageViewSize.height < scrollViewSize
            .height ? (scrollViewSize.height - imageViewSize.height) / 2 : 0
        let horizontalInset = imageViewSize.width < scrollViewSize
            .width ? (scrollViewSize.width - imageViewSize.width) / 2 : 0
        scrollView.contentInset = UIEdgeInsets(
            top: verticalInset,
            left: horizontalInset,
            bottom: verticalInset,
            right: horizontalInset
        )
    }

    private func addDismissButton() {
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        let image = UIImage(named: "ic_close", in: .module, compatibleWith: .none)?.withRenderingMode(.alwaysTemplate)
        dismissButton.setImage(image, for: .normal)
        dismissButton.tintColor = .white
        dismissButton.isAccessibilityElement = true
        dismissButton.accessibilityLabel = ParleyLocalizationKey.close.localized()

        view.addSubview(dismissButton)

        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            dismissButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
        ])

        dismissButton.addTarget(self, action: #selector(MessageImageViewController.dismissTapped), for: .touchUpInside)
    }

    @objc
    private func dismissTapped() {
        dismissWithSwipeToDismiss(1)
    }

    // MARK: Swipe to dismiss
    private func addSwipeToDismissPanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(MessageImageViewController.handleSwipeToDismiss)
        )
        panGestureRecognizer.cancelsTouchesInView = false

        view.addGestureRecognizer(panGestureRecognizer)
    }

    @objc
    private func handleSwipeToDismiss(_ panGestureRecognizer: UIPanGestureRecognizer) {
        let translation = panGestureRecognizer.translation(in: view)
        let translationY = translation.y
        let translationYAbsolute = abs(translationY)

        var frame = scrollView.frame
        frame.origin = CGPoint(x: 0, y: translationY)
        scrollView.frame = frame

        view.alpha = 1 - (translationYAbsolute / 300)

        if panGestureRecognizer.state == .ended {
            if translationYAbsolute > 100 {
                dismissWithSwipeToDismiss(translationY)
            } else {
                resetSwipeToDismiss()
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
        adjustContentInset()
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}
