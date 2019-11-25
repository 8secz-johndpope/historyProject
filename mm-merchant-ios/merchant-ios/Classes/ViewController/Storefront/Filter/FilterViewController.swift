//
//  FilterViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 19/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import NMRangeSlider
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
protocol FilterStyleDelegate: NSObjectProtocol {
    //@param selectedFilterCategories to hold value of the original categories, which is selected in FilterCatController
    func filterStyle(_ styles: [Style], styleFilter: StyleFilter, selectedFilterCategories: [Cat]?)
    func filterStyle(_ styles: [Style], styleFilter: StyleFilter, isNeedSnapshot: Bool)
    func fetchStyles(_ styles: [Style], styleFilter: StyleFilter, isNeedSnapshot: Bool, merchantId: Int?, completion: ((SearchResponse?) -> Void)?)
    func didSelectMerchantFromSearch(_ merchant: Merchant?)
    func didSelectBrandFromSearch(_ brand: Brand?)
}

class FilterViewController : MmViewController, FilterStyleDelegate {
    static let LowestPrice: Float = 0
    static let HighestPrice: Float = Constants.Price.Highest
    
    private enum SectionType: Int {
        case filterBadgeSection = 0
        case filterButtonSection = 1
        case filterDetailsSection = 2
    }
    
    private enum DetailSectionRow: Int {
        case titleRow = 0
        case sliderRow = 1
        case brandRow = 2
        case categoryRow = 3
        case colorRow = 4
        case sizeRow = 5
        case merchantRow = 6
        
        static func numberOfRow() -> Int{
            return DetailSectionRow.merchantRow.rawValue + 1
        }
        
        func name() -> String{
            switch self{
            case .titleRow:
                return String.localize("LB_CA_FILTER_PRICE_RANGE")
            case .sliderRow:
                return String.localize("")
            case .brandRow:
                return String.localize("LB_CA_BRAND")
            case .categoryRow:
                return String.localize("LB_CA_CATEGORY")
            case .colorRow:
                return String.localize("LB_CA_COLOUR")
            case .sizeRow:
                return String.localize("LB_CA_SIZE")
            case .merchantRow:
                return String.localize("LB_CA_MERCHANT")
            }
        }
    }
    
    private enum ButtonSectionRow: Int {
        case discount = 0
        case overseas = 1
        
        static func numberOfRow() -> Int{
            return ButtonSectionRow.overseas.rawValue + 1
        }
        
        func name() -> String{
            switch self{
            case .discount:
                return String.localize("LB_CA_DISCOUNT")
            case .overseas:
                return String.localize("LB_OVERSEAS")
            }
        }
    }
    
    private final let DefaultHeaderID = "DefaultHeaderID"
    private final let CellId = "Cell"
    private final let FilterCellId = "FilterItemCell"
    private final let FilterPriceRangeCellId = "FilterPriceRangeCellId"
    private final let BadgeCellId = "BadgeCell"
    private final let ButtonCellId = "ButtonCell"
    private final let TitleCellId = "TitleCell"
    
    private static let StepPrice: Float = 2500
    private final let BadgeCellHeight: CGFloat = 40
    private final let BadgeCellWidth: CGFloat = 86
    private final let CellHeight: CGFloat = 60
    private let ButtonCellHeight: CGFloat = 60 + ScreenBottom
    private let HeaderHeight: CGFloat = 1
    var stylesTotal = 0
    
    var styles = [Style]()
    var skuIds: String?
    var originalStyles = [Style]()
    var aggregations = Aggregations()
    var displayingAggregations: Aggregations?
    var originalAggregations: Aggregations?
    
    var originalStyleFilter : StyleFilter!{
        didSet{
            isShowCategorySubFilter = !(originalStyleFilter.cats.count > 0)
            
            isShowColorSubFilter = !(originalStyleFilter.colors.count > 0)
            
            isShowSizeSubFilter = !(originalStyleFilter.sizes.count > 0)
            
            self.updateFilterTags()
        }
    }
    var styleFilter: StyleFilter! {
        didSet{
            self.updateFilterTags()
            if let filterHeaderView = filterHeaderView {
                filterHeaderView.styleFilter = self.styleFilter
            }
        }
    }
    private var generalStyleFilter : StyleFilter!
    private var badges: [Badge] = [] // This  array is used to show badges
    private var searchBadges: [Badge] = [] // This array is only updated from listBadge()
    var selectedFilterCategories: [Cat]? // Capture current selected categories to re-displaying
    
    private var filterHeaderView: FilterHeaderView?
    private var buttonCell = ButtonCell()
    private var filterPriceRangeCell: FilterPriceRangeCell?
    private var loadingProgressView: UIProgressView!
    private var filterCollectionViewFlowLayout: FilterCollectionViewFlowLayout?
    
    private var isPlayingProgressViewAnimation = false
    private var playProgressViewCompletionAnimation = false
    private var isEnterFromBrand = false
    private var isEnterFromMerchant = false
    private var isShowCategorySubFilter = true
    private var isShowColorSubFilter = true
    private var isShowSizeSubFilter = true
    private var isResetTapped = false
    private var sliderMoved = false
    
    private var currentFilterSelectedAnimationData: FilterSelectedAnimationData?
    private var analyticsRecordList = [String: AnalyticsActionRecord]()
    
    private var sectionList = [SectionType]()
    
    weak var filterStyleDelegate: FilterStyleDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initAnalyticLog()
        initSections()
        
        self.createBackButton()
        self.createRightButton(String.localize("LB_CA_RESET"), action: #selector(FilterViewController.resetTapped))
        
        setupCollectionView()
        createProgressView()
        
        self.buttonCell.backgroundColor = UIColor.white
        self.buttonCell.button.setTitle(String.localize("LB_CA_CONFIRM"), for: UIControlState())
        self.buttonCell.button.addTarget(self, action: #selector(FilterViewController.confirmClicked), for: .touchUpInside)
        
        self.updateItemCount()
        
        self.generalStyleFilter = self.originalStyleFilter.clone()
        self.updateGeneralStyleFilter()
        
        self.handleListBadge()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.buttonCell.frame = CGRect(x: 0, y: collectionView.frame.maxY - ButtonCellHeight, width: self.view.bounds.width, height: ButtonCellHeight)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = String.localize("LB_CA_FILTER")
        
        self.collectionView?.delegate = self
        self.collectionView?.dataSource = self
        self.collectionView.backgroundColor = UIColor.white
        
        self.sliderMoved = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Stop animating progress when view disappeared
        resetProgressView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        var rect = self.view.frame
        rect.size.height = Constants.ScreenSize.SCREEN_HEIGHT - rect.originY
        self.view.frame = rect
        
        self.buttonCell.button.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        
        if let resetButton = self.navigationItem.rightBarButtonItem?.customView as?  UIButton {
            resetButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        }
    }
    
    override func backButtonClicked(_ button: UIButton) {
        super.backButtonClicked(button)
        button.isEnabled = false
    }

    // MARK: - View Setup
    
    func initSections() {
        sectionList.removeAll()
        sectionList.append(.filterBadgeSection)
        sectionList.append(.filterButtonSection)
        sectionList.append(.filterDetailsSection)
    }
    
    func setupCollectionView() {
        let filterCollectionViewFlowLayout = FilterCollectionViewFlowLayout()
        filterCollectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        filterCollectionViewFlowLayout.itemSize = CGSize(width: self.view.frame.width, height: 120)
        filterCollectionViewFlowLayout.badgeSection = self.sectionList.index(of: .filterBadgeSection) ?? -1
        filterCollectionViewFlowLayout.buttonSection = self.sectionList.index(of: .filterButtonSection) ?? -1
        self.filterCollectionViewFlowLayout = filterCollectionViewFlowLayout
        
        self.collectionView.setCollectionViewLayout(filterCollectionViewFlowLayout, animated: true)
        
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: ButtonCellHeight, right: 0)
        
        self.collectionView.register(FilterHeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: FilterHeaderView.ViewIdentifier)
        self.collectionView.register(UICollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: DefaultHeaderID)
        self.collectionView.register(HeaderView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "Header")
        
        self.collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: CellId)
        self.collectionView.register(FilterItemCell.self, forCellWithReuseIdentifier: FilterCellId)
        self.collectionView.register(FilterPriceRangeCell.self, forCellWithReuseIdentifier: FilterPriceRangeCellId)
        self.collectionView.register(ButtonCell.self, forCellWithReuseIdentifier: ButtonCellId)
        self.collectionView.register(TitleCell.self, forCellWithReuseIdentifier: TitleCellId)
        self.collectionView.register(BadgeCell.self, forCellWithReuseIdentifier: BadgeCellId)
        
        self.collectionView.frame = CGRect(x: self.view.bounds.minX, y: self.view.bounds.minY, width: self.view.bounds.width, height: self.view.bounds.height - ButtonCellHeight)
        
        self.collectionView.alwaysBounceVertical = true
        
        self.edgesForExtendedLayout = UIRectEdge()
        
        self.view.insertSubview(self.buttonCell, aboveSubview: self.collectionView)
    }
    
    func getDetailSectionCell(indexPath:IndexPath) -> UICollectionViewCell {
        if let filterCell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCellId, for: indexPath) as?
            FilterItemCell{
            filterCell.showArrowView(true)
        }
        if let detailSectionRow = DetailSectionRow(rawValue: indexPath.row) {
            switch detailSectionRow {
            case .titleRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TitleCellId, for: indexPath) as! TitleCell
                cell.textLabel.text = detailSectionRow.name()
                
                return cell
            case .sliderRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterPriceRangeCellId, for: indexPath) as! FilterPriceRangeCell
                cell.setMinPrice(styleFilter.priceFrom)
                cell.setMaxPrice(styleFilter.priceTo)
                
                cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
                
                cell.filterPriceRangeCellDelegate = self
                
                filterPriceRangeCell = cell
                
                return cell
            case .brandRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCellId, for: indexPath) as! FilterItemCell
                cell.textLabel.text = detailSectionRow.name()
                cell.selectLabel.text = ""
                
                if !self.styleFilter.brands.isEmpty{
                    let strongDisplayingAggregations = self.displayingAggregations ?? Aggregations()
                    
                    var displayingBrands = [Brand]()
                    displayingBrands = self.styleFilter.brands.filter({(strongDisplayingAggregations.brandArray.contains($0.brandId)) || (self.originalStyleFilter.hasBrand($0.brandId))})
                    
                    for brand : Brand in displayingBrands {
                        cell.selectLabel.text! += brand.brandName
                        cell.selectLabel.text! += " "
                    }
                }
                
                cell.showArrowView(!isEnterFromBrand)
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                
                return cell
            case .categoryRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCellId, for: indexPath) as! FilterItemCell
                cell.textLabel.text = detailSectionRow.name()
                cell.selectLabel.text = ""
                
                if !self.styleFilter.cats.isEmpty{
                    let strongDisplayingAggregations = self.displayingAggregations ?? Aggregations()
                    
                    var displayingCats = [Cat]()
                    
                    displayingCats = self.styleFilter.cats.filter({(strongDisplayingAggregations.categoryArray.contains($0.categoryId)) ||
                        (self.originalStyleFilter.hasCategory($0.categoryId))})
                    
                    for cat: Cat in displayingCats{
                        if cat.categoryId != DiscoverCategoryViewController.AllCategory{
                            cell.selectLabel.text! += cat.categoryName
                            cell.selectLabel.text! += " "
                        }
                    }
                }
                
                cell.showArrowView(isShowCategorySubFilter)
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                return cell
            case .colorRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCellId, for: indexPath) as! FilterItemCell
                cell.textLabel.text = detailSectionRow.name()
                cell.selectLabel.text = ""
                
                if !self.styleFilter.colors.isEmpty{
                    let strongDisplayingAggregations = self.displayingAggregations ?? Aggregations()
                    
                    var displayingColors = [Color]()
                    displayingColors = self.styleFilter.colors.filter({(strongDisplayingAggregations.colorArray.contains($0.colorId)) ||
                        (self.originalStyleFilter.hasColor($0.colorId))})
                    
                    for color : Color in displayingColors{
                        cell.selectLabel.text! += color.colorName
                        cell.selectLabel.text! += " "
                    }
                }
                
                cell.showArrowView(isShowColorSubFilter)
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                return cell
            case .sizeRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCellId, for: indexPath) as! FilterItemCell
                cell.textLabel.text = detailSectionRow.name()
                cell.selectLabel.text = ""
                
                if !self.styleFilter.sizes.isEmpty{
                    let strongDisplayingAggregations = self.displayingAggregations ?? Aggregations()
                    
                    var displayingSizes = [Size]()
                    displayingSizes = self.styleFilter.sizes.filter({(strongDisplayingAggregations.sizeArray.contains($0.sizeId)) ||
                        (self.originalStyleFilter.hasSize($0.sizeId))})
                    
                    for size : Size in displayingSizes{
                        cell.selectLabel.text! += size.sizeName
                        cell.selectLabel.text! += " "
                    }
                    
                }
                
                cell.showArrowView(isShowSizeSubFilter)
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                return cell
            case .merchantRow:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCellId, for: indexPath) as! FilterItemCell
                cell.textLabel.text = detailSectionRow.name()
                cell.selectLabel.text = ""
                
                if !self.styleFilter.merchants.isEmpty{
                    let strongDisplayingAggregations = self.displayingAggregations ?? Aggregations()
                    
                    var displayingMerchants = [Merchant]()
                    displayingMerchants = self.styleFilter.merchants.filter({(strongDisplayingAggregations.merchantArray.contains($0.merchantId)) ||
                        (self.originalStyleFilter.hasMerchant($0.merchantId))})
                    
                    for merchant : Merchant in displayingMerchants{
                        cell.selectLabel.text! += merchant.merchantName
                        cell.selectLabel.text! += " "
                    }
                }
                
                cell.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
                cell.showArrowView(!isEnterFromMerchant)
                
                return cell
            }
        }
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
    }
    
    // MARK: - Collection View data source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectionList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch collectionView {
        case self.collectionView:
            let sectionType = sectionList[section]
            switch sectionType {
            case .filterBadgeSection:
                return self.badges.count
            case .filterButtonSection:
                return ButtonSectionRow.numberOfRow()
            case .filterDetailsSection:
                return DetailSectionRow.numberOfRow()
            }
        default:
            break
        }
        
        return 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch collectionView {
        case self.collectionView:
            let sectionType = sectionList[indexPath.section]
            switch sectionType {
            case .filterBadgeSection:
                if !self.badges.isEmpty {
                    let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: BadgeCellId, for: indexPath) as! BadgeCell
                    cell.border()
                    cell.highlight(self.badges[indexPath.row].isSelected)
                    cell.label.text = self.badges[indexPath.row].badgeName
                    cell.backgroundColor = UIColor.white
                    return cell
                }
            case .filterButtonSection:
                let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: BadgeCellId, for: indexPath) as! BadgeCell
                cell.border()
                cell.backgroundColor = UIColor.white
                
                if let buttonSection = ButtonSectionRow(rawValue: indexPath.row){
                    cell.label.text = buttonSection.name()
                    switch buttonSection{
                    case .discount:
                        cell.highlight(self.styleFilter.isSale == 1)
                    case .overseas:
                        cell.highlight(self.styleFilter.isCrossBorder == 1)
                        
                    }
                }
                
                cell.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
                return cell
            case .filterDetailsSection:
                return getDetailSectionCell(indexPath: indexPath)
            }
            
        default:
            break
        }
        
        return collectionView.dequeueReusableCell(withReuseIdentifier: CellId, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if collectionView == self.collectionView {
            switch kind {
            case UICollectionElementKindSectionHeader:

                let sectionType = sectionList[indexPath.section]
                switch sectionType {
                case .filterBadgeSection:
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FilterHeaderView.ViewIdentifier, for: indexPath) as! FilterHeaderView
                    view.backgroundColor = UIColor.filterBackground()
                    view.cellPadding = 10
                    view.isAbleRemoveMainFilter = true
                    view.styleFilter = self.styleFilter
                    view.didUpdateStyleFilter = { [weak self] (styleFilter, filterType) -> Void in
                        if let strongSelf = self {
                            strongSelf.styleFilter = styleFilter
                            strongSelf.updateGeneralStyleFilter()
                            strongSelf.filterStyle(strongSelf.styles, styleFilter: strongSelf.styleFilter, selectedFilterCategories: nil)
                            
                            let isUpdateDisplayingAggregations = strongSelf.styleFilter.equal(strongSelf.generalStyleFilter)
                            strongSelf.handleSearchStyle(isUpdateDisplayingAggregations)
                            switch filterType {
                            case .badge,.crossBorder,.newProduct,.priceRange,.sale:
                                if !isUpdateDisplayingAggregations{
                                    strongSelf.searchStyleWithGeneralStyleFilter()
                                }
                            default:
                                break
                            }
                        }
                    }
                    
                    view.currentFilterSelectedAnimationData = currentFilterSelectedAnimationData
                    
                    filterHeaderView = view
                    return view
                case .filterButtonSection:
                    let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
                    view.label.text = ""
                    return view
                default:
                    break
                }
                
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
                headerView.label.text = ""
                return headerView
            default:
                assert(false, "Unexpected element kind")
                
                let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
                return headerView
            }
        } else {
            assert(false, "Unexpected collection view requesting header view")
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "Header", for: indexPath) as! HeaderView
            return headerView
        }
    }
    
    // MARK: - Collection view delegate flow layout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case self.collectionView:
            let sectionType = sectionList[indexPath.section]
            switch sectionType {
            case .filterBadgeSection:
                if self.badges.isEmpty {
                    return CGSize.zero
                }
                else{
                    return CGSize(width: BadgeCellWidth, height: BadgeCellHeight)
                }
            case .filterButtonSection:
                return CGSize(width: BadgeCellWidth, height: BadgeCellHeight)
            default:
                return CGSize(width: view.width, height: CellHeight)
            }
            
        default:
            break
        }
        
        return CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        switch collectionView {
        case self.collectionView:
            let sectionType = sectionList[section]
            switch sectionType {
            case .filterBadgeSection, .filterButtonSection:
                return 14.0
            default:
                break
            }
        default:
            break
        }
        
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch collectionView {
        case self.collectionView:
            let sectionType = sectionList[section]
            switch sectionType {
            case .filterBadgeSection:
                if !self.badges.isEmpty {
                    return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
                }
            case .filterButtonSection:
                return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
            default:
                break
            }
            
        default:
            break
        }
        
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize{
        switch collectionView {
        case self.collectionView:
            let sectionType = sectionList[section]
            switch sectionType {
            case .filterBadgeSection:
                if isHiddenFilterHeader(){
                    return CGSize.zero
                }
                return CGSize(width: view.width, height: FilterHeaderView.DefaultHeight)
            case .filterButtonSection:
                return CGSize(width: view.width, height: HeaderHeight)
            default:
                break
            }
            
        default:
            break
        }
        
        return CGSize.zero
    }
    
    // MARK: - Collection view delegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case self.collectionView:
            let sectionType = sectionList[indexPath.section]
            if let cell = collectionView.cellForItem(at: indexPath) {
                switch sectionType {
                case .filterButtonSection:
                    
                    var isButtonSelected = false
                    
                    var filterTagName = ""
                    
                    if let buttonSectionRow = ButtonSectionRow(rawValue: indexPath.row){
                        switch buttonSectionRow{
                        case .discount:
                            if self.styleFilter.isSale == -1 {
                                self.styleFilter.isSale = 1
                                isButtonSelected = true
                                filterTagName = buttonSectionRow.name()
                            } else {
                                self.styleFilter.isSale = -1
                            }
                            
                            cell.recordAction(.Tap, sourceRef: isButtonSelected ? "Discount-Unchecked" : "Discount-Checked", sourceType: .Button, targetRef: isButtonSelected ? "Discount-Checked" : "Discount-Unchecked", targetType: .Button)
                        case .overseas:
                            if self.styleFilter.isCrossBorder == -1 {
                                self.styleFilter.isCrossBorder = 1
                                isButtonSelected = true
                                filterTagName = buttonSectionRow.name()
                            } else {
                                self.styleFilter.isCrossBorder = -1
                            }
                            
                            cell.recordAction(.Tap, sourceRef: isButtonSelected ? "Oversea-Unchecked" : "Oversea-Checked", sourceType: .Button, targetRef: isButtonSelected ? "Oversea-Checked" : "Oversea-Unchecked", targetType: .Button)
                        }
                    }
                    
                    self.generalStyleFilter.isSale = self.styleFilter.isSale
                    self.generalStyleFilter.isCrossBorder = self.styleFilter.isCrossBorder
                
                    //Init data for Filter Selection Animation
                    if isButtonSelected{
                        self.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: self.view, filterTagName: filterTagName, completion: {
                            self.collectionView.isUserInteractionEnabled = true
                        })
                        self.currentFilterSelectedAnimationData?.filterSelectedAnimationState = FilterSelectedAnimationState.start
                    }
                    
                    //Search styles and update the displaying filter items
                    let isUpdateDisplayingAggregations = self.styleFilter.equal(self.generalStyleFilter)
                    
                    self.handleSearchStyle(isUpdateDisplayingAggregations, completion: {
                        if isButtonSelected{
                            self.showFilterSelectionAnimationForBadgeCellAtIndexPath(indexPath)
                        }
                    })
                    
                    if !isUpdateDisplayingAggregations{
                        self.searchStyleWithGeneralStyleFilter()
                    }
                case .filterBadgeSection:
                    let badge = self.badges[indexPath.row]
                    badge.isSelected = !badge.isSelected
                    
                    if badge.isSelected {
                        self.styleFilter.addTag(badge.badgeName, id: badge.badgeId, filterType: FilterType.badge)
                    } else {
                        self.styleFilter.removeTag(badge.badgeId, filterType: FilterType.badge)
                    }
                    
                    self.styleFilter.badges = self.badges.filter(){ $0.isSelected }
                    self.generalStyleFilter.badges = self.badges.filter(){ $0.isSelected }
                    
                    //Init data for Filter Selection Animation
                    if badge.isSelected{
                        self.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: self.view, filterTagName: badge.badgeName, completion: {
                            self.collectionView.isUserInteractionEnabled = true
                        })
                        self.currentFilterSelectedAnimationData?.filterSelectedAnimationState = FilterSelectedAnimationState.start
                    }
                    
                    let isUpdateDisplayingAggregations = self.styleFilter.equal(self.generalStyleFilter)
                    self.handleSearchStyle(isUpdateDisplayingAggregations, completion: {
                        if badge.isSelected{
                           self.showFilterSelectionAnimationForBadgeCellAtIndexPath(indexPath)
                        }
                    })
                    if !isUpdateDisplayingAggregations{
                        self.searchStyleWithGeneralStyleFilter()
                    }
                    
                    let uncheckedRef = "\(badge.badgeNameInvariant.uppercased())-Unchecked"
                    let checkedRef = "\(badge.badgeNameInvariant.uppercased())-Checked"
                    
                    cell.recordAction(.Tap, sourceRef: badge.isSelected ? uncheckedRef : checkedRef, sourceType: .Button, targetRef: badge.isSelected ? checkedRef : uncheckedRef, targetType: .Button)
                default:
                    // Section FilterDetailsSection
                    if let detailSectionRow = DetailSectionRow(rawValue: indexPath.row) {
                        switch detailSectionRow {
                        case .brandRow:
                            cell.recordAction(
                                .Tap,
                                sourceRef: "Brand",
                                sourceType: .Button,
                                targetRef: "PLP-Filter-Brand",
                                targetType: .View
                            )
                            
                            if !isEnterFromBrand{
                                let filterBrandController = FilterBrandController()
                                self.initDataForSubFilterViewController(filterBrandController)
                                
                                self.navigationController?.push(filterBrandController, animated: true)
                            }
                        case .categoryRow:
                            cell.recordAction(
                                .Tap,
                                sourceRef: "Category",
                                sourceType: .Button,
                                targetRef: "PLP-Filter-Category",
                                targetType: .View
                            )
                            
                            if isShowCategorySubFilter{
                                let filterCatController = FilterCatController()
                                self.initDataForSubFilterViewController(filterCatController)
                                
                                self.navigationController?.push(filterCatController, animated: true)
                            }
                            
                        case .colorRow:
                            cell.recordAction(
                                .Tap,
                                sourceRef: "Color",
                                sourceType: .Button,
                                targetRef: "PLP-Filter-Color",
                                targetType: .View
                            )
                            
                            if isShowColorSubFilter{
                                let filterColorController = FilterColorController()
                                self.initDataForSubFilterViewController(filterColorController)
                                
                                self.navigationController?.push(filterColorController, animated: true)
                            }
                            
                        case .sizeRow:
                            cell.recordAction(
                                .Tap,
                                sourceRef: "Size",
                                sourceType: .Button,
                                targetRef: "PLP-Filter-Size",
                                targetType: .View
                            )
                            
                            if isShowSizeSubFilter{
                                let filterSizeController = FilterSizeController()
                                self.initDataForSubFilterViewController(filterSizeController)
                                
                                self.navigationController?.push(filterSizeController, animated: true)
                            }
                            
                        case .merchantRow:
                            cell.recordAction(
                                .Tap,
                                sourceRef: "Merchant",
                                sourceType: .Button,
                                targetRef: "PLP-Filter-Merchant",
                                targetType: .View
                            )
                            if !isEnterFromMerchant{
                                let filterMerchantController = FilterMerchantController()
                                self.initDataForSubFilterViewController(filterMerchantController)
                                
                                self.navigationController?.push(filterMerchantController, animated: true)
                            }
                            
                        default:
                            break
                        }
                    }
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Data
    
    func handleSearchStyle(_ isUpdateDisplayingAggregations: Bool = false, completion: (()->())? = nil) {
        startProgressView()
        
        firstly {
            return self.searchStyle(isUpdateDisplayingAggregations)
            }.then { _ -> Void in
                self.reloadAllData()
                if let action = completion{
                    action()
                }
        }.always {
             self.stopProgressView()
        }
    }
    
    func handleListBadge(){
        startProgressView()
        
        firstly {
            return self.listBadge()
            }.then { _ -> Void in
                self.updateDisplayingBadges()
                
                self.reloadAllData()
            }.always {
                self.stopProgressView()
        }
    }
    
    private func updateDisplayingBadges(){
        self.badges = self.searchBadges.filter( {$0.badgeId != 0} )
        self.badges = self.badges.filter( {(self.aggregations.badgeArray).contains($0.badgeId)} )
        
        for badge: Badge in self.badges {
            badge.isSelected = false
            for badgeSelected: Badge  in self.styleFilter.badges {
                if badge.badgeId == badgeSelected.badgeId{
                    badge.isSelected = true
                }
            }
        }
    }
    
    // MARK: - Progress View
    
    private func createProgressView() {
        self.loadingProgressView = UIProgressView(frame: CGRect(x: 0, y: self.collectionView.frame.originY + 1, width: self.view.bounds.sizeWidth, height: 40))
        loadingProgressView.isHidden = true
        loadingProgressView.progress = 0
        loadingProgressView.trackTintColor = UIColor.clear
        self.view.addSubview(loadingProgressView)
    }
    
    private func startProgressView() {
        if let navigationController = self.navigationController {
            navigationController.view.isUserInteractionEnabled = false
        }
        
        isPlayingProgressViewAnimation = false
        playProgressViewCompletionAnimation = false
        
        loadingProgressView.progress = 0
        loadingProgressView.layoutIfNeeded()
        loadingProgressView.alpha = 1
        loadingProgressView.isHidden = false
        
        loadingProgressView.progress = 0.99
        
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveLinear, animations: {
            self.loadingProgressView.layoutIfNeeded()
        }, completion: { (isSuccess) in
            self.isPlayingProgressViewAnimation = false
            
            if self.playProgressViewCompletionAnimation {
                self.stopProgressView()
            }
        })
    }
    
    private func stopProgressView() {
        if self.isPlayingProgressViewAnimation {
            self.playProgressViewCompletionAnimation = true
        } else {
            loadingProgressView.progress = 1
            
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveLinear, animations: {
                self.loadingProgressView.layoutIfNeeded()
            }, completion: { (isSuccess) in
                if isSuccess {
                    UIView.animate(withDuration: 0.25, delay: 0.5, options: .curveLinear, animations: {
                        self.loadingProgressView.alpha = 0
                    }, completion: { (isSuccess) in
                        self.resetProgressView()
                    })
                } else {
                    self.resetProgressView()
                }
            })
        }
    }
    
    private func resetProgressView() {
        self.loadingProgressView.isHidden = true
        
        self.isPlayingProgressViewAnimation = false
        self.playProgressViewCompletionAnimation = false
        
        if let navigationController = self.navigationController {
            navigationController.view.isUserInteractionEnabled = true
        }
    }
    
    private func handleSearchStyleFromPriceUpdates(_ isShowSelectedAnimation: Bool = false){
        self.collectionView?.reloadData()
        self.startProgressView()
        
        let isUpdateDisplayingAggregations = self.styleFilter.equal(self.generalStyleFilter)
        
        firstly{
            return self.searchStyle(isUpdateDisplayingAggregations)
            }.then { _ -> Void in
                self.reloadAllData()
                if let view = self.filterHeaderView{
                    if let data = self.currentFilterSelectedAnimationData, data.filterSelectedAnimationState == .start && isShowSelectedAnimation{
                        data.fromView = self.filterPriceRangeCell
                        self.collectionView.isUserInteractionEnabled = false
                        view.showSelectedAnimation(data)
                    }
                }
            }.always {
                self.stopProgressView()
        }
        
        if !isUpdateDisplayingAggregations{
            self.searchStyleWithGeneralStyleFilter()
        }
    }
    
    // MARK: - UIBarButton Reset
    
    @objc func resetTapped(_ sender: UIBarButtonItem) {
        
        analyticsRecordList.removeAll()
        sender.recordAction(
            .Tap,
            sourceRef: "Reset",
            sourceType: .Button,
            targetRef: "PLP-Filter",
            targetType: .View
        )
        
        sender.isEnabled = false
//        self.styleFilter.reset()
        if self.selectedFilterCategories != nil {
            for cat in self.selectedFilterCategories! {
                if cat.categoryList?.count > 0 {
                    for subCat in cat.categoryList! {
                        subCat.isSelected = false
                    }
                }
            }
        }
        
        self.selectedFilterCategories = nil
        
        self.styleFilter = originalStyleFilter.clone()
        self.styleFilter.removeEmptyNameFilterTags()
        
        self.generalStyleFilter = originalStyleFilter.clone()
        
        self.sliderMoved = true
        
        self.isResetTapped = true
        
        self.reloadAllData()
        
        self.startProgressView()
        
        firstly {
            return self.searchStyle(true)
        }.then {_ -> Void in
            if self.originalAggregations != nil{
                self.aggregations = self.originalAggregations!.clone()
            }
    
            self.reloadAllData()
        }.always {
            self.stopProgressView()
            sender.isEnabled = true
        }
    }
    
    // MARK: - UIButton Click Confirm
    
    @objc func confirmClicked(_ sender: UIButton) {

        //Send analytics
        self.sendAnalyticsFiltering(confirmButton: sender)
        
        self.startProgressView()
        
        firstly {
            self.searchStyle()
        }.then { _ -> Void in
            
        }.always {
            self.stopProgressView()
            self.styleFilter.isFilter = true
            
            //if Reset Tapped we restore the original categories state in the PLP
            if self.isResetTapped {
                self.selectedFilterCategories = []
            }
            self.filterStyleDelegate.filterStyle(self.styles, styleFilter: self.styleFilter, selectedFilterCategories: self.selectedFilterCategories)
            self.navigationController?.popViewController(animated:true)
        }
    }
    
    // MARK: - FilterStyle Delegate
    
    //@param selectedFilterCategories to hold value of the original categories, which is selected in FilterCatController
    func filterStyle(_ styles: [Style], styleFilter: StyleFilter, selectedFilterCategories: [Cat]?) {
        isResetTapped = false
        
        //Selected Filter categories != nil means user not selected filter by categories or user pressing back button on FilterViewController.swift
        if selectedFilterCategories != nil {
            if selectedFilterCategories!.count > 0 {
                self.selectedFilterCategories = selectedFilterCategories
            } else {
                //selectedFilterCategories not null and empty: means user tapped reset button
                //So we force clear selected filter categories state
                self.selectedFilterCategories = nil
                let styleFilterSnapShot = StyleFilter.getSnapshot()
                self.styleFilter.cats = styleFilterSnapShot.cats
            }
        }
        
        self.reloadAllData()
        self.filterStyle(styles, styleFilter: styleFilter, isNeedSnapshot: false)
    }
    
    func filterStyle(_ styles: [Style], styleFilter: StyleFilter, isNeedSnapshot: Bool) {
        self.styles = styles
        self.styleFilter = styleFilter
        if isNeedSnapshot {
            styleFilter.saveSnapshot()
        }
        self.reloadAllData()
        
        startProgressView()
        firstly{
            return self.searchStyle()
            }.then { _ -> Void in
                self.reloadAllData()
            }.always {
                self.stopProgressView()
        }
    }
    
    func fetchStyles(_ styles: [Style], styleFilter: StyleFilter, isNeedSnapshot: Bool, merchantId: Int?, completion: ((SearchResponse?) -> Void)?) {
        
    }
    
    func didSelectBrandFromSearch(_ brand: Brand?) {
    }
    
    func didSelectMerchantFromSearch(_ merchant: Merchant?) {
    }
    
    // MARK: - Search Style
    
    func searchStyle(_ isUpdateDisplayingAggregations: Bool = false, completion: (()->())? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchStyle(self.styleFilter, skuIds: skuIds) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                            
                            strongSelf.stylesTotal = styleResponse.hitsTotal
                            if let styles = styleResponse.pageData {
                                strongSelf.styles = styles
                                if strongSelf.originalStyles.isEmpty{
                                    strongSelf.originalStyles = styles
                                }
                            } else {
                                strongSelf.styles = []
                            }
                            
                            if let aggregations = styleResponse.aggregations {
                                strongSelf.aggregations = aggregations
                            } else {
                                strongSelf.aggregations = Aggregations()
                            }
                            
                            strongSelf.updateDisplayingBadges()
                            
                            if strongSelf.displayingAggregations == nil{
                                strongSelf.displayingAggregations = strongSelf.aggregations.clone()
                            }
                            
                            if isUpdateDisplayingAggregations{
                                if let aggregations = styleResponse.aggregations {
                                    strongSelf.displayingAggregations = aggregations
                                } else {
                                    strongSelf.displayingAggregations = Aggregations()
                                }
                                
                                if let aggregations = strongSelf.displayingAggregations {
                                    strongSelf.styleFilter.updateFilterTags(aggregations: aggregations)
                                    if let headerView = strongSelf.filterHeaderView {
                                        headerView.reloadView()
                                    }
                                }
                                
                                strongSelf.reloadAllData()
                            }
                        }
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    @discardableResult
    func searchStyleWithGeneralStyleFilter(_ completion: (()->())? = nil) -> Promise<Any> {
        
        return Promise{ fulfill, reject in
            SearchService.searchStyle(self.generalStyleFilter, skuIds: skuIds) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                            
                            if let aggregations = styleResponse.aggregations {
                                strongSelf.displayingAggregations = aggregations
                            } else {
                                strongSelf.displayingAggregations = Aggregations()
                            }
                            
                            strongSelf.updateDisplayingBadges()
                            
                            strongSelf.reloadAllData()
                            
                            if let aggregations = strongSelf.displayingAggregations {
                                strongSelf.styleFilter.updateFilterTags(aggregations: aggregations)
                                if let headerView = strongSelf.filterHeaderView {
                                    headerView.reloadView()
                                }
                            }
                            
                            if let action = completion{
                                action()
                            }
                        }
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    // MARK: - List Badge API
    
    func listBadge()-> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchBadge() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        strongSelf.searchBadges = Mapper<Badge>().mapArray(JSONObject: response.result.value) ?? []
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    // MARK: - Reload
    
    func reloadAllData() {
        
        self.collectionView?.reloadData()
        self.updateItemCount()
    }
    
    func updateItemCount() {
        self.buttonCell.itemLabel.text = String.localize("LB_CA_NUM_PRODUCTS_1") + String(self.stylesTotal) + String.localize("LB_CA_NUM_PRODUCTS_2")
    }
    
    // MARK: - Helpers
    
    private func updateGeneralStyleFilter(){
        self.generalStyleFilter.isSale = self.styleFilter.isSale
        self.generalStyleFilter.isCrossBorder = self.styleFilter.isCrossBorder
        self.generalStyleFilter.badges = self.styleFilter.badges
        self.generalStyleFilter.priceFrom = self.styleFilter.priceFrom
        self.generalStyleFilter.priceTo = self.styleFilter.priceTo
    }
    
    func isHiddenFilterHeader() -> Bool{
        return (styleFilter.filterTags.count == 0) || (styleFilter.filterTags.filter{$0.isEnable} ).count == 0
    }
    
    private func updateFilterTags(){
        if originalStyleFilter != nil{
            if originalStyleFilter.brands.count == 1{
                isEnterFromBrand = true
            }
            if originalStyleFilter.merchants.count == 1{
                isEnterFromMerchant = true
            }
        }
    }
    
    private func initDataForSubFilterViewController(_ viewController: SubFilterBaseViewController){
        viewController.filterStyleDelegate = self
        viewController.aggregations = self.displayingAggregations
        viewController.originalStyleFilter = self.originalStyleFilter.clone()
        viewController.styleFilter = self.styleFilter
        viewController.searchStyleFilter = self.generalStyleFilter
        viewController.styles = self.originalStyles
    }
    
    // MARK: Animation
    
    func showFilterSelectionAnimationForBadgeCellAtIndexPath(_ indexPath: IndexPath){
        if let cell = self.collectionView.dequeueReusableCell(withReuseIdentifier: self.BadgeCellId, for: indexPath) as? BadgeCell{
            if let view = self.filterHeaderView{
                if let data = self.currentFilterSelectedAnimationData{
                    data.fromView = cell
                    self.collectionView.isUserInteractionEnabled = false
                    view.showSelectedAnimation(data)
                }
            }
        }
    }
    
    // MARK: Analytic
    
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            viewLocation: "PLP-Filter",
            viewType: "Product"
        )
    }
    
    func sendAnalyticsFiltering(confirmButton: UIButton) {
        
        //Analytic Records
        for analyticRecord in analyticsRecordList.values {
            AnalyticsManager.sharedManager.recordAction(analyticRecord)
        }
        
        //Analytic Records
        if self.styleFilter.isSale == 1 {
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Tap, sourceRef: "Discount-Unchecked", sourceType: .Button, targetRef: "Discount-Checked", targetType: .Button)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
        }
        
        //Analytic Records
        if self.styleFilter.isCrossBorder == 1 {
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Tap, sourceRef: "Oversea-Unchecked", sourceType: .Button, targetRef: "Oversea-Checked", targetType: .Button)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
        }
        
        //Analytic Records
        for badge: Badge in self.styleFilter.badges {
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Tap, sourceRef: "\(badge.badgeId)-Unchecked", sourceType: .Badge, targetRef: "\(badge.badgeId)-Checked", targetType: .Badge)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
        }
        
        //Analytic Records
        for brand: Brand in self.styleFilter.brands {
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Submit, sourceRef: "PLP-Filter-Brand", sourceType: .View, targetRef: "\(brand.brandId)", targetType: .Brand)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
        }
        
        //Analytic Records
        for cat: Cat in self.styleFilter.cats {
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Submit, sourceRef: "PLP-Filter-Category", sourceType: .View, targetRef: "\(cat.categoryId)", targetType: .Category)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
        }
        
        //Analytic Records
        for color: Color in self.styleFilter.colors {
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Submit, sourceRef: "PLP-Filter-Color", sourceType: .View, targetRef: "\(color.colorId)", targetType: .Color)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
        }
        
        //Analytic Records
        for size: Size in self.styleFilter.sizes {
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Submit, sourceRef: "PLP-Filter-Color", sourceType: .View, targetRef: "\(size.sizeId)", targetType: .Size)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
        }
        
        //Analytic Records
        for merchant: Merchant in self.styleFilter.merchants {
            let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Submit, sourceRef: "PLP-Filter-Merchant", sourceType: .View, targetRef: "\(merchant.merchantId)", targetType: .Merchant)
            AnalyticsManager.sharedManager.recordAction(actionRecord)
        }
        
        //Analytic Records
        confirmButton.recordAction(
            .Tap,
            sourceRef: "Submit",
            sourceType: .Button,
            targetRef: "PLP",
            targetType: .View
        )
    }
}

extension FilterViewController: FilterPriceRangeCellDelegate{
    func filterPriceRangeCell(didChangePriceRange filterPriceRangeCell: FilterPriceRangeCell, minPrice: Int?, maxPrice: Int?) {
        //Analytics
        var sourceRef = ""
        if let minPrice = minPrice{
            sourceRef = "\(minPrice)"
        }
        
        var targetRef = ""
        if let maxPrice = maxPrice{
            targetRef = "\(maxPrice)"
        }
        
        let actionRecord = AnalyticsManager.createActionRecord(analyticsViewKey: analyticsViewRecord.viewKey, actionTrigger: .Slide, sourceRef: sourceRef, sourceType: .PriceRangeFrom, targetRef: targetRef, targetType: .PriceRangeTo)
        self.analyticsRecordList["PriceRange"] = actionRecord
        
        //Search styles with selected price range
        if let minPrice = minPrice, let maxPrice = maxPrice, minPrice > maxPrice{
            self.styleFilter.priceFrom = maxPrice
            self.styleFilter.priceTo = minPrice
        }
        else{
            self.styleFilter.priceFrom = minPrice
            self.styleFilter.priceTo = maxPrice
        }
        
        if self.generalStyleFilter.priceFrom == self.styleFilter.priceFrom && self.generalStyleFilter.priceTo == self.styleFilter.priceTo{
            return
        }
        else{
            self.generalStyleFilter.priceFrom = self.styleFilter.priceFrom
            self.generalStyleFilter.priceTo = self.styleFilter.priceTo
        }
        
        if self.styleFilter.priceCount() == 1{
            self.currentFilterSelectedAnimationData = FilterSelectedAnimationData(inView: self.view, filterTagName: self.styleFilter.getFormattedPriceRange(), completion: {
                
                self.collectionView.isUserInteractionEnabled = true
                
                if self.currentFilterSelectedAnimationData?.isExistFilterTagCell ?? false{
                    self.handleSearchStyleFromPriceUpdates(false)
                }
            })
            self.currentFilterSelectedAnimationData?.filterSelectedAnimationState = FilterSelectedAnimationState.start
            self.currentFilterSelectedAnimationData?.filterType = FilterType.priceRange
            if let view = self.filterHeaderView{
                self.currentFilterSelectedAnimationData?.isExistFilterTagCell = (view.priceRangeFilterTagCell != nil)
                if self.currentFilterSelectedAnimationData?.isExistFilterTagCell ?? false{
                    self.currentFilterSelectedAnimationData?.fromView = self.filterPriceRangeCell
                    self.collectionView.isUserInteractionEnabled = false
                    view.showSelectedAnimation(self.currentFilterSelectedAnimationData)
                }
                
            }
        }
        else{
            if self.currentFilterSelectedAnimationData?.isExistFilterTagCell ?? false{
                self.handleSearchStyleFromPriceUpdates(false)
            }
        }
        
        if !(self.currentFilterSelectedAnimationData?.isExistFilterTagCell ?? false){
            self.handleSearchStyleFromPriceUpdates(true)
        }
    }
}

internal class FilterCollectionViewFlowLayout : UICollectionViewFlowLayout {
    var badgeSection: Int = -1
    var buttonSection: Int = -1
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        let padding: CGFloat = 14
        let startLeftMargin: CGFloat = 16
        var leftMargin: CGFloat = startLeftMargin
        var maxY: CGFloat = -1.0
        
        attributes?.forEach { layoutAttribute in
            if (layoutAttribute.indexPath.section == self.badgeSection ||
                layoutAttribute.indexPath.section == self.buttonSection) &&
                layoutAttribute.representedElementKind != UICollectionElementKindSectionHeader &&
                layoutAttribute.representedElementKind != UICollectionElementKindSectionFooter{
                if layoutAttribute.frame.origin.y >= maxY {
                    leftMargin = startLeftMargin
                }
                layoutAttribute.frame.origin.x = leftMargin
                
                leftMargin += layoutAttribute.frame.width + padding
                maxY = max(layoutAttribute.frame.maxY , maxY)
            }
        }
        
        return attributes
    }
}
