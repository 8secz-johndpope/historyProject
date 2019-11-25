//
//  CategoryShortcutView.swift
//  merchant-ios
//
//  Created by Alan YU on 2/4/2018.
//	Copyright © 2018 WWE & CO. All rights reserved.
//

class CategoryShortcutView: UIView {
    
    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.estimatedItemSize = CGSize(width: 100, height: 28)
        let collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        collectionView.backgroundColor = .white
        collectionView.register(UINib(nibName: "FilterCategoryCell", bundle: nil), forCellWithReuseIdentifier: "FilterCategoryCell")
        collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 10)
        return collectionView
    } ()
    
    var categories: [Cat]?
    var filter: StyleFilter?
    
    var applyFilterHandler: ((_ filter: StyleFilter?) -> Void)?
    
    func reload() {
        categoryCollectionView.reloadData()
    }
    
    private func commonInit() {
        backgroundColor = .white
        addSubview(categoryCollectionView)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        categoryCollectionView.frame = bounds
    }
}

extension CategoryShortcutView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cat = categories![indexPath.item]
        let filtered = !isFiltered(for: cat)
        
        filter?.isFilter = true
        
        filter?.removeNestedCategory(cat)
        
        if filtered {
            filter?.cats.append(cat)
        }
        
        applyFilterHandler?(filter)
        
        collectionView.reloadData()
    }
    
    private func isFiltered(for cat: Cat) -> Bool {
        var isSelected = false
        if let filter = filter {
            if filter.cats.contains(cat) {
                isSelected = true
            } else {
                if let list = cat.categoryList {
                    for cat in list {
                        if filter.cats.contains(cat) {
                            isSelected = true
                            break
                        }
                    }
                }
            }
        }
        return isSelected
    }
    
}

extension CategoryShortcutView: UICollectionViewDelegateFlowLayout {

}

extension CategoryShortcutView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FilterCategoryCell", for: indexPath) as! FilterCategoryCell
        let cat = categories![indexPath.item]
        cell.picked = isFiltered(for: cat)
        cell.category = cat
        return cell
    }
    
}
