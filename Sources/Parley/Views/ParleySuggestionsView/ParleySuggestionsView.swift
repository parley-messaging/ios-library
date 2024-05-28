import UIKit

final class ParleySuggestionsView: UIView {
    
    @IBOutlet weak var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let suggestionCollectionViewCell = UINib(nibName: SuggestionCollectionViewCell.reuseIdentifier, bundle: .module)
            self.collectionView.register(suggestionCollectionViewCell, forCellWithReuseIdentifier: SuggestionCollectionViewCell.reuseIdentifier)
            
            self.collectionView.dataSource = self
            self.collectionView.delegate = self
        }
    }
    
    @IBOutlet weak var heightLayoutConstraint: NSLayoutConstraint!
    
    var appearance: ParleySuggestionsViewAppearance = ParleySuggestionsViewAppearance() {
        didSet {
            self.apply(self.appearance)
        }
    }
    weak var delegate: ParleySuggestionsViewDelegate?
    
    var isEnabled = true {
        didSet {
            self.collectionView.alpha = self.isEnabled ? 1 : 0.5
        }
    }
    
    private var suggestions: [String]?
    
    func render(_ suggestions: [String]) {
        self.suggestions = suggestions
        
        let maxHeight = getMaxHeight()
        heightLayoutConstraint.constant = maxHeight
        collectionView.reloadData()
    }
    
    private func apply(_ appearance: ParleySuggestionsViewAppearance) {
        let maxHeight = getMaxHeight()
        heightLayoutConstraint.constant = maxHeight
        collectionView.reloadData()
    }
    
    private func getMaxHeight() -> CGFloat {
        var maxHeight: CGFloat = 0
        if let suggestions {
            suggestions.forEach { suggestion in
                let height = SuggestionCollectionViewCell.calculateHeight(self.appearance.suggestion, suggestion)
                if height > maxHeight {
                    maxHeight = height
                }
            }
        }
        return maxHeight
    }
    
    // MARK: View
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setup()
    }
    
    private func setup() {
        self.loadXib()
        
        self.apply(self.appearance)
    }
    
    private func loadXib() {
        Bundle.module.loadNibNamed("ParleySuggestionsView", owner: self, options: nil)
        
        self.contentView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.contentView)
        
        NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: self.contentView, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: self.contentView, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .top, relatedBy: .equal, toItem: self.contentView, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: self.contentView, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
    }
}

extension ParleySuggestionsView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.suggestions?.count ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let suggestionCollectionView = collectionView.dequeueReusableCell(
                withReuseIdentifier: SuggestionCollectionViewCell.reuseIdentifier,
                for: indexPath
            ) as? SuggestionCollectionViewCell,
            let suggestion = self.suggestions?[indexPath.row] else
        {
            return UICollectionViewCell()
        }

        suggestionCollectionView.appearance = self.appearance.suggestion
        suggestionCollectionView.render(suggestion)

        return suggestionCollectionView
    }
}

extension ParleySuggestionsView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !self.isEnabled { return }
        
        guard let suggestion = self.suggestions?[indexPath.row] else { return }
        
        self.delegate?.didSelect(suggestion)
    }
}

extension ParleySuggestionsView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let maxHeight = getMaxHeight()
        let balloonContentInsets = (appearance.suggestion.balloonContentInsets?.left ?? 0) + (appearance.suggestion.balloonContentInsets?.right ?? 0)
        let suggestionInsets = (appearance.suggestion.suggestionInsets?.left ?? 0) + (appearance.suggestion.suggestionInsets?.right ?? 0)
        let maxItemWidth = appearance.suggestion.suggestionMaxWidth + balloonContentInsets + suggestionInsets
        return CGSize(width: maxItemWidth, height: maxHeight)
    }
}
