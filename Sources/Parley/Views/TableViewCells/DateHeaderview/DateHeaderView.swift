import UIKit

final class DateHeaderView: UIView {
    
    // MARK: UI Elements
    private let pillView = UIView()
    private let dateLabel = UILabel()
    
    private var topLayoutConstraint: NSLayoutConstraint!
    private var leftLayoutConstraint: NSLayoutConstraint!
    private var bottomLayoutConstraint: NSLayoutConstraint!
    private var rightLayoutConstraint: NSLayoutConstraint!
    private var allConstraints: [NSLayoutConstraint] {
        [
            topLayoutConstraint, bottomLayoutConstraint,
            leftLayoutConstraint, rightLayoutConstraint
        ]
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
}

// MARK: - Methods
extension DateHeaderView {
    
    func configure(date: String, appearance: DateTableViewCellAppearance) {
        dateLabel.text = date
        apply(appearance: appearance)
    }
}

// MARK: - Privates
private extension DateHeaderView {
    
    func setup() {
        setupPillView()
        setupDateLabel()
    }
    
    func setupPillView() {
        pillView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(pillView)
        
        NSLayoutConstraint.activate([
            pillView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pillView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            pillView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            pillView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            pillView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
        ])
    }
    
    func setupDateLabel() {
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        pillView.addSubview(dateLabel)
        
        topLayoutConstraint = dateLabel.topAnchor.constraint(equalTo: pillView.topAnchor)
        leftLayoutConstraint = dateLabel.leadingAnchor.constraint(equalTo: pillView.leadingAnchor)
        rightLayoutConstraint = dateLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor)
        bottomLayoutConstraint = dateLabel.bottomAnchor.constraint(equalTo: pillView.bottomAnchor)
        
        NSLayoutConstraint.activate(allConstraints)
    }
    
    func apply(appearance: DateTableViewCellAppearance) {
        pillView.backgroundColor = appearance.backgroundColor
        pillView.layer.cornerRadius = CGFloat(appearance.cornerRadius)

        dateLabel.font = appearance.textFont
        dateLabel.textColor = appearance.textColor

        dateLabel.adjustsFontForContentSizeCategory = true
        
        topLayoutConstraint.constant = appearance.contentInset?.top ?? 0
        leftLayoutConstraint.constant = appearance.contentInset?.left ?? 0
        bottomLayoutConstraint.constant = (appearance.contentInset?.bottom ?? 0) * -1
        rightLayoutConstraint.constant = (appearance.contentInset?.right ?? 0) * -1
    }
}
