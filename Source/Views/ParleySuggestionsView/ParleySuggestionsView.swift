internal class ParleySuggestionsView: UIView {
    
    @IBOutlet weak var contentView: UIView! {
        didSet {
            self.contentView.backgroundColor = UIColor.clear
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            let suggestionCollectionViewCell = UINib(nibName: "SuggestionCollectionViewCell", bundle: Bundle(for: type(of: self)))
            self.collectionView.register(suggestionCollectionViewCell, forCellWithReuseIdentifier: "SuggestionCollectionViewCell")
            
            self.collectionView.dataSource = self
            self.collectionView.delegate = self
            
            if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
                flowLayout.estimatedItemSize = CGSize(width: 1, height: 1)
            }
        }
    }
    
    @IBOutlet weak var heightLayoutConstraint: NSLayoutConstraint!
    
    var appearance: ParleySuggestionsViewAppearance = ParleySuggestionsViewAppearance() {
        didSet {
            self.apply(self.appearance)
        }
    }
    var delegate: ParleySuggestionsViewDelegate?
    
    var isEnabled = true {
        didSet {
            self.collectionView.alpha = self.isEnabled ? 1 : 0.5
        }
    }
    
    private var suggestions: [String]?
    
    internal func render(_ suggestions: [String]) {
        self.suggestions = suggestions
        
        var maxHeight: CGFloat = 0
        suggestions.forEach { suggestion in
            let height = SuggestionCollectionViewCell.calculateHeight(self.appearance.suggestion, suggestion)
            if height > maxHeight {
                maxHeight = height
            }
        }
        
        if let flowLayout = self.collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.estimatedItemSize = CGSize(width: 1, height: maxHeight)
        }
        
        self.heightLayoutConstraint.constant = maxHeight
        
        self.collectionView.reloadData()
    }
    
    private func apply(_ appearance: ParleySuggestionsViewAppearance) {
        //
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
        Bundle(for: type(of: self)).loadNibNamed("ParleySuggestionsView", owner: self, options: nil)
        
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
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let suggestionCollectionView = collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestionCollectionViewCell", for: indexPath) as? SuggestionCollectionViewCell else { return UICollectionViewCell() }
        guard let suggestion = self.suggestions?[indexPath.row] else { return UICollectionViewCell() }
        
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
