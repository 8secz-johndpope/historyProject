//
//  FilterCatController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class FilterCatController: FilterCollectionBaseViewController {
    
    private let HeaderHeight: CGFloat = 40
    private final let MarginLeft: CGFloat = 20
    private final let LineSpacing: CGFloat = 10
    private final let CellHeight: CGFloat = 25
    private final let TextMargin: CGFloat = 30
    
    private final let FilterCatCellId = "FilterCatCell"
    private final let KeyHeader = "Header"
    
    private var isMale: Bool { // 判断当前搜索关键字中是否包含"男"字
        get {
            if let styleFilter = styleFilter {
                if styleFilter.queryString.length > 0 {
                    return styleFilter.queryString.contain(String.localize("LB_CA_GENDER_M"))
                }
            }
            
            return false
        }
    }
    
    var cats: [Cat] = []
    var filteredCats: [Cat] = []{
        didSet{
            self.buttonCell.isHidden = isHideSubmitButton()
            if let strongAggregations = self.aggregations{
                filteredCats = filteredCats.filter({(strongAggregations.categoryArray.contains($0.categoryId))})
                for filteredCat in filteredCats {
                    filteredCat.categoryList = (filteredCat.categoryList ?? []).filter({(strongAggregations.categoryArray.contains($0.categoryId))})
                }
            }
            collectionView.isHidden = !hasDataSource()
            updateNoItemView()
        }
    }
    
    private var textFont = UIFont()
    
    var tagSelectedCount = 0
    
    var radioHeaderViews = [String:UIView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_FILTER_CATEGORY")
        
        loadCategories()
        setupCollectionView()
        
        let label = UILabel()
        label.formatSize(13)
        textFont = label.font
        initAnalyticLog()
    }
    
    override func refresh(_ sender: Any) {
        super.refresh(sender)
        
        loadCategories()
    }
    
    // MARK: - Setup
    
    override func setupCollectionView() {
        super.setupCollectionView()
        collectionView.register(FilterCatCell.self, forCellWithReuseIdentifier: FilterCatCellId)
        collectionView.register(PickerCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: KeyHeader)
        collectionView.register(RadioHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: RadioHeaderView.ViewIdentifier)
        collectionView.backgroundColor = UIColor.white
    }
    
    override func isHideSubmitButton() -> Bool {
        return (filteredCats.count == 0)
    }
    
    // MARK: - Data
    
    func loadCategories() {
        showLoading()
        
        CacheManager.sharedManager.fetchAllCategories(completion: { [weak self] (cats, nextPage, error) in
            if let strongSelf = self{
                var level2Cats = [Cat]()
                for cat in cats ?? []{
                    if let cats = cat.categoryList{
                        level2Cats.append(contentsOf: cats)
                    }
                }
                
                strongSelf.cats = level2Cats.filter{$0.categoryId != 0 && $0.categoryId != DiscoverCategoryViewController.AllCategory}
                strongSelf.filteredCats = strongSelf.cats
                if strongSelf.isMale { // 排序关键字的数组
                    var tempCats : [Cat] = [Cat]()
                    for cat in strongSelf.filteredCats {
                        if cat.isMale == 1 && cat.isFemale != 1 {
                            tempCats.append(cat)
                            strongSelf.filteredCats.remove(cat)
                        }
                    }
                    strongSelf.filteredCats.insert(contentsOf: tempCats, at: 0)
                }
                
                strongSelf.updateSelectedCatForFilterCats()
                strongSelf.collectionView.reloadData()
                
                strongSelf.stopLoading()
                strongSelf.refreshControl.endRefreshing()
            }
        })
    }
    
    // MARK: - UICollectionView data source
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        if collectionView == self.filterCollectionView{
            return super.numberOfSections(in: collectionView)
        }
        return filteredCats.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.filterCollectionView{
            return super.collectionView(collectionView, numberOfItemsInSection: section)
        }
        if let categoryList = self.filteredCats[section].categoryList {
            return categoryList.count
        }
        return 0
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCatCellId, for: indexPath) as! FilterCatCell
        let tag = self.filteredCats[indexPath.section].categoryList![indexPath.row]
        cell.nameLabel.text = tag.categoryName
        cell.selected(tag.isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplaySupplementaryView view: UICollectionReusableView, forElementKind elementKind: String, atIndexPath indexPath: IndexPath) {
        if collectionView == self.collectionView{
            switch elementKind {
            case UICollectionElementKindSectionHeader:
                if let radioHeaderView = view as? RadioHeaderView{
                    let view = UIView(frame: radioHeaderView.frame)
                    collectionView.addSubview(view)
                    view.isHidden = true
                    radioHeaderViews["\(indexPath.section)"] = view
                }
            default:
                break
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == self.filterCollectionView{
            return super.collectionView(collectionView, viewForSupplementaryElementOfKind: kind, at: indexPath)
        }
        
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RadioHeaderView.ViewIdentifier, for: indexPath) as! RadioHeaderView
            let selectedCategory = self.filteredCats[indexPath.section]
            headerView.label.text = selectedCategory.categoryName
            headerView.borderView.isHidden = false
            headerView.isChecked = selectedCategory.checkSelected()
            headerView.didTappSelectAll = { [weak self] isSelectedAll -> Void in
                if let strongSelf = self{
                    selectedCategory.isSelected = isSelectedAll
                    strongSelf.updateSubCategorySelection(isSelectedAll, category: selectedCategory)
                    
                    if selectedCategory.isSelected{
                        strongSelf.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: strongSelf.view, filterTagName: selectedCategory.categoryName, completion: {
                            strongSelf.collectionView.isUserInteractionEnabled = true
                        })
                        strongSelf.currentFilterSelectedAnimationData?.filterSelectedAnimationState = FilterSelectedAnimationState.start
                    }

                    strongSelf.refreshFilterHeader()
                    strongSelf.collectionView.reloadData()
                    
                    if let fromView = strongSelf.radioHeaderViews["\(indexPath.section)"]{
                        strongSelf.showFilterSelectionAnimation(fromView)
                    }
                }
            }
            
            return headerView
        default:
            assert(false, "Unexpected element kind")
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: KeyHeader, for: indexPath) as! PickerCell
            return headerView
        }
    }
    
    // MARK: - UICollectionView delegate (Flow Layout)
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = getTextWidth(filteredCats[indexPath.section].categoryList![indexPath.row].categoryName, height: CellHeight, font: textFont)
        
        if width > view.width - MarginLeft * 2 {
            width = view.width - MarginLeft * 2
        }
        
        return CGSize(width: width, height: CellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: LineSpacing, left: MarginLeft, bottom: LineSpacing , right: MarginLeft)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == self.filterCollectionView{
            return 0
        }
        return LineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return LineSpacing
    }
    
    override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch collectionView {
        case self.filterCollectionView:
            if section == 0{
                return super.collectionView(collectionView, layout: collectionViewLayout, referenceSizeForHeaderInSection: section)
            }
        case self.collectionView:
            return CGSize(width: view.width, height: HeaderHeight)
        default:
            break
        }
        
        return CGSize.zero
    }

    // MARK: - UICollectionView delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let sectionCategory = self.filteredCats[indexPath.section]
        let selectedCat = self.filteredCats[indexPath.section].categoryList![indexPath.row]
        selectedCat.isSelected = !selectedCat.isSelected
        
        if selectedCat.isSelected {
            tagSelectedCount += 1
        } else {
            tagSelectedCount -= 1
        }
        
        self.updateStyleFilter(category: selectedCat, parentCategory: sectionCategory)
        
        //Init data for Filter Selection Animation
        var filterTagName = selectedCat.categoryName
        if sectionCategory.checkSelected(){
            filterTagName = sectionCategory.categoryName
        }
        if selectedCat.isSelected{
            self.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: self.view, filterTagName: filterTagName, completion: {
                self.collectionView.isUserInteractionEnabled = true
            })
            self.currentFilterSelectedAnimationData?.filterSelectedAnimationState = FilterSelectedAnimationState.start
        }
        
        self.refreshFilterHeader()
        collectionView.reloadData()
        
        var fromView: UIView?
        
        //Show PLP filter selection Animation
        if sectionCategory.checkSelected(), let sectionView = radioHeaderViews["\(indexPath.section)"]{
            fromView = sectionView
        }
        else if let selectedCell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCatCellId, for: indexPath) as? FilterCatCell{
            fromView = selectedCell.viewBackground
        }
        
        if let view = fromView{
            showFilterSelectionAnimation(view)
        }
    }
    
    //MARK: - Override
    
    override func hasDataSource() -> Bool{
        return (filteredCats.count > 0)
    }
    
    //MARK: - FilterHeader delegate
    
    override func didUpdateStyleFilter(_ styleFilter: StyleFilter?, filterType: FilterType){
        super.didUpdateStyleFilter(styleFilter, filterType: filterType)
        
        if filterType == FilterType.category{
            for cat in self.filteredCats {
                cat.isSelected = false
                if let styleFilter = self.styleFilter {
                    if styleFilter.cats.contains(where: {$0.categoryId == cat.categoryId}) {
                        cat.isSelected = true
                    }
                }
                
                if cat.categoryList?.count > 0 {
                    for item in cat.categoryList! {
                        item.isSelected = cat.isSelected
                        if let styleFilter = self.styleFilter {
                            if styleFilter.cats.contains(where: {$0.categoryId == item.categoryId}) {
                                item.isSelected = true
                            }
                        }
                    }
                }
            }
            self.collectionView.reloadData()
        }
        else{
            self.loadCategories()
        }
    }
    
    // MARK: - Action
    
    override func reset(_ sender: UIBarButtonItem) {
        super.reset(sender)
        
        let strongOriginalStyleFilter = originalStyleFilter ?? StyleFilter()
            
        for cat in self.filteredCats {
            if !strongOriginalStyleFilter.hasCategory(cat.categoryId){
                cat.isSelected = false
                styleFilter?.removeTag(cat.categoryId, filterType: FilterType.category)
            }
            
            if cat.categoryList?.count > 0 {
                for subCat in cat.categoryList ?? [] {
                    if !strongOriginalStyleFilter.hasCategory(subCat.categoryId){
                        subCat.isSelected = false
                        styleFilter?.removeTag(subCat.categoryId, filterType: FilterType.category)
                    }
                }
            }
        }
        
        styleFilter?.cats = originalStyleFilter?.cats ?? []
        
        refreshFilterHeader()
        
        loadCategories()
    }
    
    override func confirm(_ sender: UIButton) {
        super.confirm(sender)
        
        var selectedCats : [Cat] = []
        for cat in styleFilter?.cats ?? []{
            if cat.parentCategoryId == 0{
                selectedCats.append(cat)
            }
        }
        for cat in self.filteredCats {
            if cat.checkSelected(){
                selectedCats.append(cat)
            }else if let categoryList = cat.categoryList {
                for subCat in categoryList {
                    if subCat.isSelected {
                        selectedCats.append(subCat)
                    }
                }
            }
        }
        
        var selectedCategory: [Cat]?
        
        if selectedCats.count > 0 {
            selectedCategory = self.filteredCats
        } else {
            selectedCategory = [Cat]()
        }
        
        self.styleFilter?.cats = selectedCats
        filterStyleDelegate?.filterStyle(self.styles, styleFilter: self.styleFilter!, selectedFilterCategories: selectedCategory)
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper
    
    func getTextWidth(_ text: String, height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.width + TextMargin
    }
    
    private func updateSubCategorySelection(_ isSelected: Bool, category: Cat){
        for subCat in category.categoryList ?? [] {
            subCat.isSelected = isSelected
        }
        
        self.updateStyleFilter(category: category)
    }
    
    private func updateStyleFilter(category: Cat, parentCategory: Cat? = nil){
        
        if let parentCategory = parentCategory{
            if parentCategory.checkSelected(){
                for cat in parentCategory.categoryList ?? []{
                    if styleFilter != nil{
                        styleFilter!.removeCategory(cat.categoryId)
                    }
                }
                self.updateStyleFilter(category: parentCategory)
                return
            }
            else{
                styleFilter?.removeCategory(parentCategory.categoryId)
                for cat in parentCategory.categoryList ?? []{
                    styleFilter?.removeCategory(cat.categoryId)
                    if cat.checkSelected(){
                        styleFilter?.addTag(cat.categoryName, id: cat.categoryId, filterType: FilterType.category)
                        styleFilter?.cats.append(cat)
                    }
                }
            }
        }
        
        for cat in category.categoryList ?? []{
            if styleFilter != nil{
                styleFilter!.removeCategory(cat.categoryId)
            }
        }
        
        styleFilter?.removeCategory(category.categoryId)
        if category.checkSelected(){
            styleFilter?.addTag(category.categoryName, id: category.categoryId, filterType: FilterType.category)
            styleFilter?.cats.append(category)
        }
    }
    
    private func updateSelectedCatForFilterCats(){
        if let styleFilter = self.styleFilter{
            for cat in self.filteredCats {
                cat.isSelected = styleFilter.hasCategory(cat.categoryId)
                for subCat in cat.categoryList! {
                    if cat.isSelected{
                        subCat.isSelected = true
                    }
                    else{
                        subCat.isSelected = styleFilter.hasCategory(subCat.categoryId)
                    }
                }
            }
        }
    }
    
    private func refreshFilterHeader(){
        if let filterHeaderView = self.filterHeaderView{
            filterHeaderView.styleFilter = styleFilter ?? StyleFilter()
        }
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: nil,
            viewParameters: nil,
            viewLocation: "PLP-Filter-Category",
            viewRef: nil,
            viewType: "Product"
        )
    }
}
