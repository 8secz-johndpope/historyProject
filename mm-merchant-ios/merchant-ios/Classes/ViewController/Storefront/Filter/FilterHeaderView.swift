//
//  FilterHeaderView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

enum FilterType: Int{
    case unknown = 0,
    newProduct,
    sale,
    crossBorder,
    priceRange,
    badge,
    brand,
    category,
    color,
    size,
    merchant
}

class FilterHeaderView: UICollectionReusableView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    static let ViewIdentifier = "FilterHeaderViewID"
    static let DefaultHeight : CGFloat = 60
    var cellPadding : CGFloat = 22
    
    struct Margin{
        static let Top : CGFloat = 0
        static let Left : CGFloat = 0
        static let Bottom : CGFloat = 0
        static let Right : CGFloat = 0
    }
    
    var contentView: UIView!
    private var collectionView: UICollectionView!
    
    private var filterTags = [FilterTag]()
    
    var styleFilter = StyleFilter(){
        didSet{
            self.filterTags = styleFilter.filterTags.filter{$0.isEnable}
            self.rootCategories = styleFilter.rootCategories
            self.reloadView()
        }
    }
    
    private var rootCategories: [Cat]?
    
    var didUpdateStyleFilter: ((StyleFilter, FilterType) -> ())?
    
    var isAbleRemoveMainFilter: Bool = false
    
    var latestFilterTagCell: FilterTagCell?
    
    var didFinishLoad: (() -> Void)?
    
    var currentFilterSelectedAnimationData: FilterSelectedAnimationData?
    
    var priceRangeFilterTagCell: FilterTagCell?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let containerView = { () -> UIView in
            
            let view = UIView(frame: CGRect(x: FilterHeaderView.Margin.Left, y: FilterHeaderView.Margin.Top, width: frame.width - FilterHeaderView.Margin.Left - FilterHeaderView.Margin.Right, height: frame.height - FilterHeaderView.Margin.Top - FilterHeaderView.Margin.Bottom))
            view.backgroundColor = UIColor.clear
            
            setupCollectionView()
            
            view.addSubview(collectionView)
            return view
        } ()
        contentView = containerView
        
        addSubview(containerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.headerReferenceSize = CGSize.zero
        layout.footerReferenceSize = CGSize.zero
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.itemSize = CGSize(width: frame.width, height: frame.height)
        
        collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height), collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FilterTagCell.self, forCellWithReuseIdentifier: FilterTagCell.CellIdentifier)
    }
    
    // MARK: - Data
    
    func reloadView(){
        priceRangeFilterTagCell = nil
        filterTags = styleFilter.filterTags.filter{$0.isEnable}
        self.collectionView.reloadData()
        if filterTags.count > 0{
            let indexPath = IndexPath(row: filterTags.count - 1, section: 0)
            self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.right, animated: true)
        }
    }
    
    // MARK: - Collection View Data Source methods
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: cellPadding, bottom: 0, right: cellPadding)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterTagCell.CellIdentifier, for: indexPath) as! FilterTagCell
        
        cell.tag = indexPath.row
        
        let filterTag = self.filterTags[indexPath.row]
        cell.filterTag = filterTag
        
        if indexPath.row == self.filterTags.count - 1{
            latestFilterTagCell = cell
            if let data = currentFilterSelectedAnimationData{
                if data.filterType == FilterType.priceRange && data.isExistFilterTagCell{
                    latestFilterTagCell?.isHidden = false
                }
                else{
                    latestFilterTagCell?.isHidden = (data.filterSelectedAnimationState == .start)
                }
            }
        }
        else{
            cell.isHidden = false
        }
        
        if filterTag.filterType == .priceRange{
            priceRangeFilterTagCell = cell
        }
        
        if filterTag.isRemovable{
            cell.showDeleteButton()
        }
        else{
            cell.hideDeleteButton()
        }
        
        switch filterTag.filterType{
        case .category:
            for cate in rootCategories ?? []{
                if cate.categoryId == filterTag.id{
                    cell.hideDeleteButton()
                }
            }
        case .badge, .newProduct, .sale, .crossBorder, .priceRange:
            if !isAbleRemoveMainFilter{
                cell.hideDeleteButton()
            }
            
        default:
            break
        }
        
        cell.deleteAction = {[weak self] (filterTagCell) -> Void in
            if let strongSelf = self{
                strongSelf.removeCell(filterTagCell)
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.row == filterTags.count - 1{
            
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return cellPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let filterTag = self.filterTags[indexPath.row]
        var isShowDeleteButton = filterTag.isRemovable
        switch filterTag.filterType{
        case .category:
            for cate in rootCategories ?? []{
                if cate.categoryId == filterTag.id{
                    isShowDeleteButton = false
                }
            }
        default:
            break
        }
        return CGSize(width: FilterTagCell.getWidth(filterTag.name ?? "", isShowDeleteButton: isShowDeleteButton), height: frame.height)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return filterTags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
    
    private func removeCell(_ filterTagCell: FilterTagCell){
        let filterTag = filterTagCell.filterTag
        let filterType = filterTag.filterType
        styleFilter.removeTag(filterTag.id, filterType: filterType)
        
        switch filterType {
        case .newProduct:
            styleFilter.isNew = -1
            
        case .sale:
            styleFilter.isSale = -1
            
        case .crossBorder:
            styleFilter.isCrossBorder = -1
            
        case .priceRange:
            styleFilter.priceFrom = nil
            styleFilter.priceTo = nil
            
        case .badge:
            let badge = styleFilter.badges.filter{$0.badgeId == filterTag.id}.first
            if badge != nil{
                badge?.isSelected = false
                styleFilter.badges.remove(badge!)
            }
            
        case .brand:
            let brand = styleFilter.brands.filter{$0.brandId == filterTag.id}.first
            if brand != nil{
                styleFilter.brands.remove(brand!)
            }
            
        case .category:
            let cat = styleFilter.cats.filter{$0.categoryId == filterTag.id}.first
            if cat != nil{
                styleFilter.cats.remove(cat!)
            }
            
        case .color:
            let color = styleFilter.colors.filter{$0.colorId == filterTag.id}.first
            if color != nil{
                styleFilter.colors.remove(color!)
            }
            
        case .size:
            let size = styleFilter.sizes.filter{$0.sizeId == filterTag.id}.first
            if size != nil{
                styleFilter.sizes.remove(size!)
            }
            
        case .merchant:
            let merchant = styleFilter.merchants.filter{$0.merchantId == filterTag.id}.first
            if merchant != nil{
                styleFilter.merchants.remove(merchant!)
            }
            
        default:
            break
        }
        
        if let action = didUpdateStyleFilter{
            action(styleFilter, filterType)
        }
        
        self.reloadView()
    }
    
    //MARK: PLP selected animation
    
    func showLastFilterTagCell(_ isShow: Bool = true){
        if let cell = latestFilterTagCell{
            cell.isHidden = !isShow
        }
    }

    func showSelectedAnimation(_ filterSelectedAnimationData: FilterSelectedAnimationData?){
        currentFilterSelectedAnimationData = filterSelectedAnimationData
        Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(FilterHeaderView.startFilterSelectionAnimation), userInfo: nil, repeats: false)
    }
    
    @objc private func startFilterSelectionAnimation(){
        var fromView: UIView?
        var toView: UIView?
        var inView: UIView?
        var filterTagName: String = ""
        var completion: (()->())?
        
        if let filterSelectedAnimationData = self.currentFilterSelectedAnimationData{
            if filterSelectedAnimationData.filterSelectedAnimationState == FilterSelectedAnimationState.start{
                if filterSelectedAnimationData.filterType == .priceRange && priceRangeFilterTagCell != nil{
                    filterSelectedAnimationData.toView = priceRangeFilterTagCell?.containerView
                }
                else{
                    self.showLastFilterTagCell(false)
                    filterSelectedAnimationData.toView = latestFilterTagCell?.containerView
                }
                
                filterSelectedAnimationData.filterSelectedAnimationState = FilterSelectedAnimationState.animating
                
                if let strongFilterSelectedAnimationData = self.currentFilterSelectedAnimationData{
                    fromView = strongFilterSelectedAnimationData.fromView
                    toView = strongFilterSelectedAnimationData.toView
                    inView = strongFilterSelectedAnimationData.inView
                    filterTagName = strongFilterSelectedAnimationData.selectedFilterName
                    completion = strongFilterSelectedAnimationData.completion
                    
                    if let strongFromView = fromView, let strongToView = toView{
                        let filterTagCell = FilterTagCell()
                        filterTagCell.alpha = 0.1
                        
                        if let view = inView {
                            let frame = strongFromView.convert(strongFromView.bounds, to: view)
                            filterTagCell.frame = CGRect(x: frame.midX - FilterTagCell.getWidth(filterTagName)/2, y: frame.midY - FilterTagCell.DeleteButtonSize.height/2, width: FilterTagCell.getWidth(filterTagName), height: FilterTagCell.DeleteButtonSize.height)
                            let filerTag = FilterTag(name: filterTagName, id: 0, filterType: FilterType.unknown)
                            filterTagCell.filterTag = filerTag
                            
                            view.addSubview(filterTagCell)
                            
                            let toFrame = strongToView.convert(strongToView.bounds, to: view)
                            
                            UIView.animate(withDuration: 0.5, delay: 0,
                                                       options: .curveEaseIn,
                                                       animations: { () -> Void in
                                                        strongFilterSelectedAnimationData.filterSelectedAnimationState = .animating
                                                        filterTagCell.frame = CGRect(x: toFrame.minX, y: toFrame.minY, width: filterTagCell.width, height: filterTagCell.height)
                                                        filterTagCell.alpha = 1
                                },
                                                       completion: { (success) -> Void in
                                                        strongFilterSelectedAnimationData.filterSelectedAnimationState = .end
                                                        filterTagCell.removeFromSuperview()
                                                        self.showLastFilterTagCell(true)
                                                        if let action = completion{
                                                            action()
                                                        }
                                }
                            )
                            
                        }
                    }
                }
            }
        }
    }
}

class FilterTag: Equatable {
    
    static func ==(lhs: FilterTag, rhs: FilterTag) -> Bool {
        return lhs.id == rhs.id
    }
    
    var id = 0
    var name: String?
    var filterType: FilterType = .unknown
    var isEnable: Bool = true
    var isRemovable: Bool = true
    
    init(name: String? = "", id: Int, filterType: FilterType = FilterType.unknown){
        self.name = name
        self.id = id
        self.filterType = filterType
    }
}

class FilterTagCell: UICollectionViewCell {
    
    static let CellIdentifier = "FilterTagCellID"
    
    static let HorizontalPadding: CGFloat = 10
    
    static let DeleteButtonSize = CGSize(width: 32, height: 32)

    var deleteButton: UIButton!
    var nameLabel: UILabel!
    var containerView: UIView!
    
    var deleteAction: ((FilterTagCell) -> ())?
    
    var filterTag: FilterTag = FilterTag(id: 0) {
        didSet{
            nameLabel.text = filterTag.name ?? ""
            nameLabel.frame = CGRect(x: FilterTagCell.HorizontalPadding, y: (containerView.frame.height - FilterTagCell.DeleteButtonSize.height)/2, width: nameLabel.optimumWidth(text: filterTag.name ?? ""), height: FilterTagCell.DeleteButtonSize.height)
            containerView.frame = CGRect(x: 0, y: (frame.height - FilterTagCell.DeleteButtonSize.height)/2, width: FilterTagCell.getWidth(filterTag.name ?? ""), height: FilterTagCell.DeleteButtonSize.height)
            deleteButton.frame = CGRect(x: containerView.frame.maxX - FilterTagCell.DeleteButtonSize.width, y: (containerView.frame.height - FilterTagCell.DeleteButtonSize.height)/2, width: FilterTagCell.DeleteButtonSize.width, height: FilterTagCell.DeleteButtonSize.height)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.clipsToBounds = true
        
        containerView = UIView(frame: CGRect(x: 0, y: (frame.height - FilterTagCell.DeleteButtonSize.height)/2, width: FilterTagCell.getWidth(""), height: FilterTagCell.DeleteButtonSize.height))
        containerView.backgroundColor = UIColor.secondary1()
        containerView.layer.cornerRadius = 5.0
        
        nameLabel = UILabel(frame: CGRect(x: FilterTagCell.HorizontalPadding, y: (containerView.frame.height - FilterTagCell.DeleteButtonSize.height)/2, width: 0, height: FilterTagCell.DeleteButtonSize.height))
        nameLabel.formatSize(14)
        containerView.addSubview(nameLabel)
        
        deleteButton = UIButton(frame: CGRect(x: nameLabel.frame.maxX, y: (containerView.frame.height - FilterTagCell.DeleteButtonSize.height)/2, width: FilterTagCell.DeleteButtonSize.width, height: FilterTagCell.DeleteButtonSize.height))
        deleteButton.setImage(UIImage(named: "remove_icon"), for: UIControlState())
        deleteButton.isUserInteractionEnabled = true
        deleteButton.addTarget(self, action: #selector(deleteButtonTouched), for: .touchUpInside)
        containerView.addSubview(deleteButton)
        
        addSubview(containerView)
        
        updateTag(tag)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    class func getWidth(_ filterName: String, isShowDeleteButton: Bool = true) -> CGFloat{
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: FilterTagCell.DeleteButtonSize.height))
        label.formatSize(14)
        label.text = filterName
        if isShowDeleteButton{
            return FilterTagCell.DeleteButtonSize.width + label.optimumWidth() + 10
        }
        return label.optimumWidth() + 10
    }
    
    func updateTag(_ tag: Int) {
        self.tag = tag
        deleteButton.tag = tag
    }
    
    func showDeleteButton() {
        deleteButton.isHidden = false
    }
    
    func hideDeleteButton() {
        deleteButton.isHidden = true
        nameLabel.frame = CGRect(x: 0, y: (containerView.frame.height - FilterTagCell.DeleteButtonSize.height)/2, width: frame.width, height: FilterTagCell.DeleteButtonSize.height)
        nameLabel.textAlignment = NSTextAlignment.center
        containerView.frame = CGRect(x: 0, y: (frame.height - FilterTagCell.DeleteButtonSize.height)/2, width: frame.width, height: FilterTagCell.DeleteButtonSize.height)
    }
    
    @objc func deleteButtonTouched(_ sender: UIButton){
        if let action = deleteAction{
            action(self)
        }
    }
}

enum FilterSelectedAnimationState: Int{
    case unknown = 0,
    start,
    animating,
    end
}

class FilterSelectedAnimationData{
    var fromView: UIView?
    var toView: UIView?
    var inView: UIView?
    var selectedFilterName: String = ""
    var completion: (()->())?
    var filterSelectedAnimationState = FilterSelectedAnimationState.unknown
    var filterType: FilterType = FilterType.unknown
    var isExistFilterTagCell: Bool = false
    
    init(fromView: UIView? = nil, toView: UIView? = nil, inView: UIView?, filterTagName: String = "", completion: (()->())? = nil){
        self.fromView = fromView
        self.toView = toView
        self.inView = inView
        self.selectedFilterName = filterTagName
        self.completion = completion
    }
}
