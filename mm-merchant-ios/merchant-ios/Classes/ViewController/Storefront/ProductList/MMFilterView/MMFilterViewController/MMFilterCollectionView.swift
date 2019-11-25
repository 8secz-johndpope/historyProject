//
//  MMFilterCollectionView.swift
//  storefront-ios
//
//  Created by Demon on 19/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class MMFilterCollectionView: UIView, UICollectionViewDelegateFlowLayout {
    
    var aggregations: Aggregations = Aggregations() // 需要展示的id集合
    public var priceRange:(min: Int?, max: Int?) = (nil, nil) {
        didSet {
            if let min = priceRange.min {
                minPriceString = "\(min)"
            }
            if let max = priceRange.max {
                maxPriceString = "\(max)"
            }
            filterCollectionView.reloadSections([MMFilterType.priceRange.rawValue])
        }
    }
    
    public var selectedGenderType: MMFilterGenderType = .unKnow // 当前选中的性别
    private lazy var genderList: [GenderModel] = []
    private var genderType: MMFilterGenderType = .unKnow { // 品类中的性别种类
        didSet {
            genderList.removeAll()
            switch genderType {
            case .allGender:
                let female = GenderModel(gender: 0, isSelect: selectedGenderType == .female ? true : false)
                let male = GenderModel(gender: 1, isSelect: selectedGenderType == .male ? true : false)
                genderList.append(female)
                genderList.append(male)
                break
            case .female:
                let female = GenderModel(gender: 0, isSelect: selectedGenderType == .female ? true : false)
                genderList.append(female)
                break
            case .male:
                let male = GenderModel(gender: 1, isSelect: selectedGenderType == .male ? true : false)
                genderList.append(male)
                break
            case .unKnow:
                break
            }
        }
    }
    
    private var allCategoryList: [Cat] = [] // 持有一份所有的三级品类
    var Level2CategoryList: [Cat] = [] { // 二级品类数据源
        didSet {
            let allGenderList = Level2CategoryList.filter({($0.isMale == 1 && $0.isFemale == 1) || ($0.isMale == 0 && $0.isFemale == 0)})
            let maleList = Level2CategoryList.filter({($0.isMale == 1 && $0.isFemale == 0)})
            let femaleList = Level2CategoryList.filter({($0.isFemale == 1 && $0.isMale == 0)})
            if allGenderList.count > 0 || (femaleList.count > 0 && maleList.count > 0) { // 判断当前品类中的性别种类
                genderType = .allGender
            } else if femaleList.count > 0 {
                genderType = .female
            } else if maleList.count > 0 {
                genderType = .male
            } else {
                genderType = .unKnow
            }
            var level3Cats = [Cat]()
            aggregations.categoryArray.forEach { (categoryId) in // 需要和aggregation的顺序一致,因为前六个为热门搜索
                Level2CategoryList.forEach({ (level2Cat) in
                    for level3Cat in level2Cat.categoryList! {
                        if level3Cat.categoryId == categoryId {
                            level3Cats.append(level3Cat)
                            break
                        }
                    }
                })
            }
            allCategoryList = level3Cats
            categoryList = level3Cats
        }
    }
    
    var categoryList: [Cat] = [] { // 三级品类的数据源
        didSet {
            filterCollectionView.reloadSections([MMFilterType.category.rawValue])
            filterCollectionView.reloadSections([MMFilterType.gender.rawValue])
        }
    }
    
    var brandList: [Brand] = [] { // 品牌的数据源
        didSet {
            filterCollectionView.reloadSections([MMFilterType.brand.rawValue])
        }
    }
    
    var merchantList: [Merchant] = [] { // 商户的数据源
        didSet {
            filterCollectionView.reloadSections([MMFilterType.merchant.rawValue])
        }
    }
    
    var productTagbadgeList: [Badge] = [] { //商品标签数据源
        didSet {
            filterCollectionView.reloadSections([MMFilterType.productTag.rawValue])
        }
    }
    
    var colorList: [Color] = [] { // 颜色的数据源
        didSet {
            filterCollectionView.reloadSections([MMFilterType.color.rawValue])
        }
    }
    
    private let cellMargin: CGFloat = 13
    private let cellHeight: CGFloat = 32
    private var cellWidth: CGFloat {
        return (width - cellMargin*4.0)/3.0
    }
    
    private var recordSectionMore = [false,false,false,false,false,false,false] // 各区是否展开的标识
    
    private var minPriceString: String?
    private var maxPriceString: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if #available(iOS 11.0, *) {
            self.filterCollectionView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(filterCollectionView)
        addSubview(bottomView)
        addSubview(filterAllListView)
        
        loadAllBlock()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func loadAllBlock() {
        filterAllListView.resetBtnBlock = { (type) in
            self.filterCollectionView.reloadSections([type.rawValue])
            if type == MMFilterType.category {
                self.filterCollectionView.reloadSections([MMFilterType.gender.rawValue])
            }
        }
        
        filterAllListView.backBtnBlock = {
            self.endFilterAllListViewAnimation()
        }
    }
    
    /// 重置所有的条件
    public func resetAllFilterData() {
        maxPriceString = nil
        minPriceString = nil
        productTagbadgeList.forEach { (badge) in
            if badge.isSelected {
                badge.isSelected = false
            }
        }
        
        selectedGenderType = .unKnow
        genderList.forEach { (genderModel) in
            genderModel.isSelect = false
        }
        
        categoryList.forEach { (cat) in
            if cat.isSelected {
                cat.isSelected = false
            }
        }
        
        brandList.forEach { (brand) in
            if brand.isSelected {
                brand.isSelected = false
            }
        }
        
        merchantList.forEach { (merchant) in
            if merchant.isSelected {
                merchant.isSelected = false
            }
        }
        colorList.forEach { (color) in
            if color.isSelected {
                color.isSelected = false
            }
        }
        filterCollectionView.reloadData()
    }
    
    /// 获取选择的条件
    public func confirmAllFilterData() -> (minPrice: Int?, maxPrice: Int?, selectedCategoryList: [Cat]?, selectedBrandList: [Brand]?, selectedMerchantList: [Merchant]?, selectedProductTagList: [Badge]?, selectedColorList: [Color]?) {
        let min = Int(minPriceString ?? "0")
        let max = Int(maxPriceString ?? "0")
        
        var selectedCategoryList = categoryList.filter({$0.isSelected == true})
        if selectedCategoryList.count == 0 && (selectedGenderType == .female || selectedGenderType == .male) {
            selectedCategoryList = categoryList
        }
        let selectedBrandList = brandList.filter({$0.isSelected == true})
        let selectedMerchantList = merchantList.filter({$0.isSelected == true})
        let selectedProductBadgeList = productTagbadgeList.filter({$0.isSelected == true})
        let selectedColorList = colorList.filter({$0.isSelected == true})
        return (min != 0 ? min : nil,max != 0 ? max : nil,selectedCategoryList,selectedBrandList,selectedMerchantList,selectedProductBadgeList,selectedColorList)
    }
    
    // MARK: -  lazyload
    
    private lazy var filterCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.footerReferenceSize = CGSize(width: 0, height: 0)
        let statusHeight: CGFloat = IsIphoneX ? 34.0 : 20
        let collectionView = UICollectionView(frame: CGRect(x: 0, y: statusHeight, width: width, height: height - FilterBottomViewHeight - ScreenBottom - statusHeight), collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.white
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(MMFilterCollectionViewCell.self, forCellWithReuseIdentifier: "MMFilterCollectionViewCell")
        collectionView.register(MMFilterPriceRangeViewCell.self, forCellWithReuseIdentifier: "MMFilterPriceRangeViewCell")
        collectionView.register(UINib(nibName: "MMFilterCollectionHeaderView", bundle: Bundle.main), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMFilterCollectionHeaderView")
        collectionView.register(UICollectionViewCell.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "MMFilterCollectionViewFooterView")
        return collectionView
    }()
    
    private lazy var filterAllListView: MMFilterAllListView = {
        let v = MMFilterAllListView(frame: CGRect(x: width, y: 0, width: width, height: ScreenHeight))
        return v
    }()
    
    lazy var bottomView: MMBottomView = {
        let v = MMBottomView(frame: CGRect(x: 0, y: height - FilterBottomViewHeight - ScreenBottom, width: width, height: FilterBottomViewHeight + ScreenBottom))
        return v
    }()
}

extension MMFilterCollectionView: MMFilterPriceRangeViewCellDelegate {
    
    func filterPriceRangeCell(filterPriceRangeCell: MMFilterPriceRangeViewCell, minPrice: Int?, maxPrice: Int?) {
        if let max = maxPrice {
            maxPriceString = "\(max)"
        }
        if let min = minPrice {
            minPriceString = "\(min)"
        }
    }
}

extension MMFilterCollectionView: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let filterSectionEnum = MMFilterType(rawValue: indexPath.section)
        if let type = filterSectionEnum {
            if indexPath.row >= 20 {
                didSelctAllCellBtn(type)
            } else {
                switch type {
                case .gender:
                    let gender = genderList[indexPath.row]
                    gender.isSelect = !gender.isSelect
                    
                    selectedGenderType = .unKnow
                    if gender.isSelect && gender.gender == 0 {
                        selectedGenderType = .female
                    }
                    if gender.isSelect && gender.gender == 1 {
                        selectedGenderType = .male
                    }
                    
                    if genderList.count > 1 {
                        let otherGender = genderList[genderList.count - indexPath.row - 1]
                        if gender.isSelect && otherGender.isSelect {
                            otherGender.isSelect = false
                        }
                    }
                    selectedGender(0)
                    break
                case .category:
                    let cat = categoryList[indexPath.row]
                    cat.isSelected = !cat.isSelected
                    filterCollectionView.reloadSections([type.rawValue - 1])
                    break
                case .brand:
                    let brand = brandList[indexPath.row]
                    brand.isSelected = !brand.isSelected
                case .merchant:
                    let merchant = merchantList[indexPath.row]
                    merchant.isSelected = !merchant.isSelected
                    break
                case .productTag:
                    let badge = productTagbadgeList[indexPath.row]
                    badge.isSelected = !badge.isSelected
                    break
                case .color:
                    let color = colorList[indexPath.row]
                    color.isSelected = !color.isSelected
                    break
                default:
                    break
                }
                filterCollectionView.reloadSections([type.rawValue])
            }
        }
    }
    
    /// 性别之后的数据筛选
    ///
    /// - Parameter type: 0:筛选性别之后, 选择相反性别之后,之前的已选择条件清除
    ///                   1:点击全部 二级界面的筛选
    private func selectedGender(_ type: Int) {
        if genderList.count > 1 {
            let female = genderList[0]
            let male = genderList[1]
            if (female.isSelect && male.isSelect) || (!female.isSelect && !male.isSelect) { //全部
                if type == 0 {
                    categoryList = allCategoryList
                } else {
                    filterAllListView.level2Categorylist = Level2CategoryList
                }
            } else if female.isSelect && !male.isSelect { // 只有女性
                if type == 0 {
                    let cancelSelectedMaleList = allCategoryList.filter({($0.isMale == 1 || $0.isFemale == 0)})
                    cancelSelectedMaleList.forEach { (cat) in
                        cat.isSelected = false
                    }
                    let femaleList = allCategoryList.filter({$0.isFemale == 1 || $0.isMale == 0})
                    categoryList = femaleList
                } else {
                    let femaleList = Level2CategoryList.filter({$0.isFemale == 1 || $0.isMale == 0})
                    filterAllListView.level2Categorylist = femaleList
                }
            } else { // 只有男性
                if type == 0 {
                    let cancelSelectedFemaleList = allCategoryList.filter({$0.isFemale == 1 || $0.isMale == 0})
                    cancelSelectedFemaleList.forEach { (cat) in
                        cat.isSelected = false
                    }
                    let maleList = allCategoryList.filter({$0.isMale == 1 || $0.isFemale == 0})
                    categoryList = maleList
                } else {
                    let maleList = Level2CategoryList.filter({$0.isMale == 1 || $0.isFemale == 0})
                    filterAllListView.level2Categorylist = maleList
                }
            }
        } else if genderList.count == 1 {
            let gender = genderList[0]
            if gender.gender == 0 { // 只有女性
                if type == 0 {
                    let cancelSelectedMaleList = allCategoryList.filter({($0.isMale == 1 || $0.isFemale == 0)})
                    cancelSelectedMaleList.forEach { (cat) in
                        cat.isSelected = false
                    }
                    let femaleList = allCategoryList.filter({$0.isFemale == 1 || $0.isMale == 0})
                    categoryList = femaleList
                } else {
                    let femaleList = Level2CategoryList.filter({$0.isFemale == 1 || $0.isMale == 0})
                    filterAllListView.level2Categorylist = femaleList
                }
            } else { // 只有男性
                if type == 0 {
                    let cancelSelectedFemaleList = allCategoryList.filter({$0.isFemale == 1 || $0.isMale == 0})
                    cancelSelectedFemaleList.forEach { (cat) in
                        cat.isSelected = false
                    }
                    let maleList = allCategoryList.filter({$0.isMale == 1 || $0.isFemale == 0})
                    categoryList = maleList
                } else {
                    let maleList = Level2CategoryList.filter({$0.isMale == 1 || $0.isFemale == 0})
                    filterAllListView.level2Categorylist = maleList
                }
            }
        }
    }
    
    private func didSelctAllCellBtn(_ type: MMFilterType) {
        switch type {
        case .category:
            selectedGender(1)
            break
        case .brand:
            filterAllListView.brandList = brandList
            break
        case .merchant:
            filterAllListView.merchantList = merchantList
            break
        case .productTag:
            break
        case .color:
            filterAllListView.colorList = colorList
            break
        default:
            break
        }
        beginFilterAllListViewAnimation()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let mmFilterType = MMFilterType(rawValue: indexPath.section)
        if mmFilterType == MMFilterType.priceRange {
            let priceCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MMFilterPriceRangeViewCell", for: indexPath) as! MMFilterPriceRangeViewCell
            priceCell.setPrice(maxPriceString, minPirce: minPriceString)
            priceCell.filterPriceRangeViewCellDelegate = self
            return priceCell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MMFilterCollectionViewCell", for: indexPath) as! MMFilterCollectionViewCell
            if let type = mmFilterType {
                cell.titleLb.isHidden = type == .color ? true : false
                cell.colorImageView.isHidden = type == .color ? false : true
                switch type {
                case .gender:
                    let gender = genderList[indexPath.row]
                    cell.titleLb.text = gender.genderName
                    cell.isSelectedCell = gender.isSelect
                    createAllCell(type, indexPath: indexPath, cell: cell)
                    break
                case .category:
                    let cat = categoryList[indexPath.row]
                    cell.titleLb.text = cat.categoryName
                    cell.isSelectedCell = cat.isSelected
                    createAllCell(type, indexPath: indexPath, cell: cell)
                    break
                case .brand:
                    let brand = brandList[indexPath.row]
                    cell.titleLb.text = brand.brandName
                    cell.isSelectedCell = brand.isSelected
                    createAllCell(type, indexPath: indexPath, cell: cell)
                    break
                case .merchant:
                    let merchant = merchantList[indexPath.row]
                    cell.titleLb.text = merchant.merchantName
                    cell.isSelectedCell = merchant.isSelected
                    createAllCell(type, indexPath: indexPath, cell: cell)
                    break
                case .productTag:
                    let badge = productTagbadgeList[indexPath.row]
                    cell.titleLb.text = badge.badgeName
                    cell.isSelectedCell = badge.isSelected
                    break
                case .color:
                    let color = colorList[indexPath.row]
                    cell.colorImageView.mm_setImageWithURL(ImageURLFactory.URLSize1000(color.colorImage, category: .color), placeholderImage: UIImage(named: "holder"))
                    cell.isSelectedCell = color.isSelected
                    break
                default:
                    break
                }
            }
            return cell
        }
    }
 
    private func createAllCell(_ type: MMFilterType, indexPath: IndexPath, cell: MMFilterCollectionViewCell) {
        if indexPath.row >= 20 {
            cell.titleLb.text = String.localize("LB_CA_ALL")
            cell.backgroundColor = UIColor.white
            cell.layer.borderWidth = 0.5
            cell.layer.borderColor = UIColor(hexString: "#F5F5F5").cgColor
            cell.titleLb.textColor = UIColor(hexString: "#6B6B6B")
            cell.titleLb.isHidden = false
            cell.colorImageView.isHidden = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMFilterCollectionHeaderView", for: indexPath) as! MMFilterCollectionHeaderView
            let filterEnum = MMFilterType(rawValue: indexPath.section)
            headerView.headerViewType = filterEnum
            headerView.contentLb.text = String.localize("LB_MORE")
            headerView.contentLb.textColor = UIColor(hexString: "#B2B2B2")
            headerView.isSelected = recordSectionMore[indexPath.section]
            headerView.arrowBtnClick = { [weak self] in
                let type = MMFilterType(rawValue: indexPath.section)
                self?.recordSectionMore[indexPath.section] = !(self?.recordSectionMore[indexPath.section])!
                if let t = type {
                    if t == .gender {
                        self?.filterCollectionView.reloadSections([MMFilterType.category.rawValue])
                    } else {
                        self?.filterCollectionView.reloadSections([indexPath.section])
                    }
                }
            }
            
            if let type = filterEnum {
                switch type {
                case .gender:
                    if categoryList.count <= 6 {
                        headerView.contentLb.text = ""
                        headerView.arrowBtn.isHidden = true
                    }
                    var categoryNames: [String] = []
                    categoryList.forEach { (cat) in
                        if cat.isSelected {
                            categoryNames.append(cat.categoryName)
                        }
                    }
                    headerView.productTagSelectedArray = categoryNames
                    break
                case .brand:
                    if brandList.count <= 6 {
                        headerView.contentLb.text = ""
                        headerView.arrowBtn.isHidden = true
                    }
                    var brandNames: [String] = []
                    brandList.forEach { (brand) in
                        if brand.isSelected {
                            brandNames.append(brand.brandName)
                        }
                    }
                    headerView.productTagSelectedArray = brandNames
                    break
                case .merchant:
                    if merchantList.count <= 6 {
                        headerView.contentLb.text = ""
                        headerView.arrowBtn.isHidden = true
                    }
                    var merchantNames: [String] = []
                    merchantList.forEach { (merchant) in
                        if merchant.isSelected {
                            merchantNames.append(merchant.merchantName)
                        }
                    }
                    headerView.productTagSelectedArray = merchantNames
                    break
                case .productTag:
                    if productTagbadgeList.count <= 3 {
                        headerView.contentLb.text = ""
                        headerView.arrowBtn.isHidden = true
                    }
                    var badgeNames: [String] = []
                    productTagbadgeList.forEach { (badge) in
                        if badge.isSelected {
                            badgeNames.append(badge.badgeName)
                        }
                    }
                    headerView.productTagSelectedArray = badgeNames
                    break
                case .color:
                    if colorList.count <= 3 {
                        headerView.contentLb.text = ""
                        headerView.arrowBtn.isHidden = true
                    }
                    var colorNames: [String] = []
                    colorList.forEach { (color) in
                        if color.isSelected {
                            colorNames.append(color.colorName)
                        }
                    }
                    headerView.productTagSelectedArray = colorNames
                    break
                default:
                    break
                }
            }
            return headerView
        } else {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "MMFilterCollectionViewFooterView", for: indexPath) as! UICollectionViewCell
            let line = UILabel()
            line.backgroundColor = UIColor(hexString: "#F1F1F1")
            footer.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.left.equalTo(footer.snp.left).offset(cellMargin)
                make.right.equalTo(footer.snp.right).offset(-cellMargin)
                make.top.bottom.equalTo(footer)
            }
            return footer
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let filterSectionEnum = MMFilterType(rawValue: section)
        if let type = filterSectionEnum {
            switch type {
            case .priceRange:
                return 1
            case .gender:
                return genderList.count
            case .category:
                return getEverySectionRowNumber(count: categoryList.count, isFold: recordSectionMore[section - 1])
            case .brand:
                return getEverySectionRowNumber(count: brandList.count, isFold: recordSectionMore[section])
            case .merchant:
                return getEverySectionRowNumber(count: merchantList.count, isFold: recordSectionMore[section])
            case .productTag:
                return getEverySectionRowNumber(count: productTagbadgeList.count, isFold: recordSectionMore[section], pageNumber: 3, isShowAll: true)
            case .color:
                return getEverySectionRowNumber(count: colorList.count, isFold: recordSectionMore[section], pageNumber: 3, isShowAll: true)
            default:
                return 0
            }
        }
        return 0
    }
    
    private func getEverySectionRowNumber(count: Int, isFold: Bool, pageNumber: Int = 6, isShowAll: Bool = false) -> Int {
        if count <= pageNumber {
            return count
        }
        if isFold {
            if isShowAll {
                return  count
            } else {
                if count > 20 {
                    return 21
                } else {
                    return count
                }
            }
        } else {
            return pageNumber
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return MMFilterType.count.rawValue
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let type = MMFilterType(rawValue: section)
        switch type! {
        case .gender, .category:
            if categoryList.count == 0 {
                return UIEdgeInsets.zero
            }
        case .brand:
            if brandList.count == 0 {
                return UIEdgeInsets.zero
            }
        case .merchant:
            if merchantList.count == 0 {
                return UIEdgeInsets.zero
            }
        case .productTag:
            if productTagbadgeList.count == 0 {
                return UIEdgeInsets.zero
            }
        case .color:
            if colorList.count == 0 {
                return UIEdgeInsets.zero
            }
        default:
            break
        }
        return UIEdgeInsets(top: cellMargin, left: cellMargin, bottom: cellMargin, right: cellMargin)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let filterSectionEnum = MMFilterType(rawValue: indexPath.section)
        if filterSectionEnum == MMFilterType.priceRange {
            return CGSize(width: width, height: 40)
        }
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let type = MMFilterType(rawValue: section)
        if type == MMFilterType.category {
            return CGSize.zero
        }
        switch type! {
        case .gender:
            if categoryList.count == 0 {
                return CGSize.zero
            }
        case .category:
            return CGSize.zero
        case .brand:
            if brandList.count == 0 {
                return CGSize.zero
            }
        case .merchant:
            if merchantList.count == 0 {
                return CGSize.zero
            }
        case .productTag:
            if productTagbadgeList.count == 0 {
                return CGSize.zero
            }
        case .color:
            if colorList.count == 0 {
                return CGSize.zero
            }
        default:
            break
        }
        return CGSize(width: frame.width, height: 30)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let type = MMFilterType(rawValue: section)
        if type == MMFilterType.gender {
            if categoryList.count > 0 {
                return CGSize(width: frame.width, height: 0.5)
            }
        }
        return CGSize.zero
    }
}

extension MMFilterCollectionView {
    
    private func beginFilterAllListViewAnimation() {
        UIView.animate(withDuration: 0.3) {
            self.filterAllListView.x = 0
        }
    }
    
    private func endFilterAllListViewAnimation() {
        UIView.animate(withDuration: 0.3) {
            self.filterAllListView.x = self.width
        }
    }
}

fileprivate class GenderModel {
    
    var genderName: String {
        get {
            if self.gender == 1 {
                return String.localize("LB_CA_CAT_M")
            } else {
                return String.localize("LB_CA_CAT_F")
            }
        }
    }
    var isSelect: Bool = false
    var gender: Int = 0 // 0:女 1:男
    
    init(gender: Int, isSelect: Bool) {
        self.gender = gender
        self.isSelect = isSelect
    }
}

