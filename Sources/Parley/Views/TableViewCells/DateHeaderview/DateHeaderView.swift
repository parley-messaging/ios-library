import UIKit

final class DateHeaderView: UIView {
    
    static let estimatedHeight: CGFloat = 30
    
    // MARK: UI Elements
    private let pillView = UIView()
    private let dateLabel = UILabel()
    
    init(appearance: DateHeaderAppearance, date: Date) {
        super.init(frame: .zero)
        setup(appearance: appearance)
        configure(date: date, style: appearance.style)
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(appearance: DateHeaderAppearance())
    }
}

// MARK: - Privates
private extension DateHeaderView {
    
    func setup(appearance: DateHeaderAppearance) {
        setupPillView()
        setupDateLabel(appearance)
        apply(appearance: appearance)
    }
    
    func setupAccesibility() {
        isAccessibilityElement = true
        accessibilityTraits = .header
    }
    
    func setupPillView() {
        pillView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(pillView)
        
        NSLayoutConstraint.activate([
            pillView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pillView.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            pillView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            pillView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 8),
            pillView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
        ])
    }
    
    func setupDateLabel(_ appearance: DateHeaderAppearance) {
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        pillView.addSubview(dateLabel)
        
        let topInset = appearance.contentInset?.top ?? 0
        let leftInset = appearance.contentInset?.left ?? 0
        let rightInset = (appearance.contentInset?.right ?? 0) * -1
        let bottomInset = (appearance.contentInset?.bottom ?? 0) * -1
        
        NSLayoutConstraint.activate([
            dateLabel.topAnchor.constraint(equalTo: pillView.topAnchor, constant: topInset),
            dateLabel.leadingAnchor.constraint(equalTo: pillView.leadingAnchor, constant: leftInset),
            dateLabel.trailingAnchor.constraint(equalTo: pillView.trailingAnchor, constant: rightInset),
            dateLabel.bottomAnchor.constraint(equalTo: pillView.bottomAnchor, constant: bottomInset)
        ])
    }
    
    func apply(appearance: DateHeaderAppearance) {
        pillView.backgroundColor = appearance.backgroundColor
        pillView.layer.cornerRadius = CGFloat(appearance.cornerRadius)

        dateLabel.font = appearance.textFont
        dateLabel.textColor = appearance.textColor

        dateLabel.adjustsFontForContentSizeCategory = true
    }
    
    func configure(date: Date, style: DateFormatter.Style) {
        let formattedDate = date.asDate(style: style)
        accessibilityLabel = formattedDate
        dateLabel.text = formattedDate
    }
}
