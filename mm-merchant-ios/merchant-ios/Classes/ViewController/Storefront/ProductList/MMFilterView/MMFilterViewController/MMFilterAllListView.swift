//
//  MMFilterAllListView.swift
//  storefront-ios
//
//  Created by Demon on 25/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class MMFilterAllListView: UIView {
    
    public var backBtnBlock: (() -> ())?
    public var resetBtnBlock: ((MMFilterType) -> ())?
    
    private var selectedCategoryList = [Cat]()
    var level2Categorylist: [Cat] = [] { // 二级品类
        didSet {
            selectedCategoryList.removeAll()
            allCollectionView.isHidden = false
            allTableView.isHidden = true
            allTableView.sc_indexViewDataSource = []
            dataSourceType = .category
            topView.topViewTitleLb.text = String.localize("LB_ALL_CATEGORY")
            
            level2Categorylist.forEach { (cat1) in
                let selectedCat = cat1.categoryList?.filter({$0.isSelected == true})
                selectedCat?.forEach({ (cat2) in
                    let cat = Cat()
                    cat.categoryId = cat2.categoryId
                    self.selectedCategoryList.append(cat)
                })
            }
            
            allCollectionView.reloadData()
            allCollectionView.scrollToTopAnimated(false)
        }
    }
    
    private var sectionTitles = [String]()
    private var brandDataList: [String : [Brand]] = [:]
    private var selectedBrandList = [Brand]() // 记录上级界面品牌选过的条件
    var brandList: [Brand] = [] {
        didSet {
            dataSourceType = .brand
            sectionTitles.removeAll()
            brandDataList.removeAll()
            selectedBrandList.removeAll()
            topView.topViewTitleLb.text = String.localize("LB_CA_ALL_BRAND")
            brandList.forEach { (brand) in
                var firstChar = brand.brandName.subStringToIndex(1).uppercased()
                firstChar = firstChar.isAlpha ? firstChar : "#"
                if brandDataList[firstChar] != nil {
                    brandDataList[firstChar]?.append(brand)
                } else {
                    brandDataList[firstChar] = [brand]
                }
                
                if brand.isSelected {
                    let selectedBrand = Brand()
                    selectedBrand.brandId = brand.brandId
                    selectedBrandList.append(selectedBrand)
                }
            }
            sectionTitles = brandDataList.keys.sorted()
            let count = sectionTitles.count
            sectionTitles.remove("#")
            if sectionTitles.count < count {
                sectionTitles.append("#")
            }
            allCollectionView.isHidden = true
            allTableView.isHidden = false
            allTableView.sc_indexViewDataSource = sectionTitles
            allTableView.reloadData()
            allTableView.setContentOffset(CGPoint.zero, animated: false)
            reloadBrandIndexView()
        }
    }
    
    private func reloadBrandIndexView() {
        let selectedList = brandList.filter({$0.isSelected == true})
        var selectedListChar = [Int]()
        selectedList.forEach { (brand) in
            var firsrChar = brand.brandName.subStringToIndex(1).uppercased()
            firsrChar = firsrChar.isAlpha ? firsrChar : "#"
            if let index = sectionTitles.index(of: firsrChar) {
                selectedListChar.append(index)
            }
        }
        selectedListChar = selectedListChar.filterDuplicates({$0})
        allTableView.sc_selectedItemsDataSource = selectedListChar as [NSNumber]
    }
    
    private var selectedMerchanList = [Merchant]()
    private var merchantDataList: [String : [Merchant]] = [:]
    var merchantList: [Merchant] = [] {
        didSet {
            dataSourceType = .merchant
            sectionTitles.removeAll()
            selectedMerchanList.removeAll()
            merchantDataList.removeAll()
            topView.topViewTitleLb.text = String.localize("LB_CA_FILTER_MERCHANT")
            merchantList.forEach { (merchant) in
                var firstChar = merchant.merchantName.subStringToIndex(1).uppercased()
                firstChar = firstChar.isAlpha ? firstChar : "#"
                if merchantDataList[firstChar] != nil {
                    merchantDataList[firstChar]?.append(merchant)
                } else {
                    merchantDataList[firstChar] = [merchant]
                }
                if merchant.isSelected {
                    let selectedMerchant = Merchant()
                    selectedMerchant.merchantId = merchant.merchantId
                    selectedMerchanList.append(selectedMerchant)
                }
            }
            sectionTitles = merchantDataList.keys.sorted()
            let count = sectionTitles.count
            sectionTitles.remove("#")
            if sectionTitles.count < count {
                sectionTitles.append("#")
            }
            allCollectionView.isHidden = true
            allTableView.isHidden = false
            allTableView.sc_indexViewDataSource = sectionTitles
            allTableView.reloadData()
            allTableView.setContentOffset(CGPoint.zero, animated: false)
            reloadMerchantIndexView()
        }
    }
    private func reloadMerchantIndexView() {
        let selectedList = merchantList.filter({$0.isSelected == true})
        var selectedListChar = [Int]()
        selectedList.forEach { (merchant) in
            var firsrChar = merchant.merchantName.subStringToIndex(1).uppercased()
            firsrChar = firsrChar.isAlpha ? firsrChar : "#"
            if let index = sectionTitles.index(of: firsrChar) {
                selectedListChar.append(index)
            }
        }
        selectedListChar = selectedListChar.filterDuplicates({$0})
        allTableView.sc_selectedItemsDataSource = selectedListChar as [NSNumber]
    }
    private var selectedColorList = [Color]()
    var colorList: [Color] = [] {
        didSet {
            dataSourceType = .color
            topView.topViewTitleLb.text = String.localize("LB_CA_FILTER_COLOR")
            selectedColorList.removeAll()
            
            colorList.forEach { (color) in
                if color.isSelected {
                    let selectedColor = Color()
                    selectedColor.colorId = color.colorId
                    selectedColorList.append(color)
                }
            }
            
            allTableView.sc_indexViewDataSource = []
            allCollectionView.isHidden = false
            allTableView.isHidden = true
            allCollectionView.reloadData()
            allCollectionView.scrollToTopAnimated(false)
            
        }
    }
    
    private var dataSourceType: MMFilterType = .unKnow
    private let cellMargin: CGFloat = 13
    private let cellHeight: CGFloat = 32
    private var cellWidth: CGFloat {
        return (width - cellMargin*4.0)/3.0
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        if #available(iOS 11.0, *) {
            self.allCollectionView.contentInsetAdjustmentBehavior = .never
            self.allTableView.contentInsetAdjustmentBehavior = .never
        }
        addSubview(allCollectionView)
        addSubview(bottomView)
        addSubview(topView)
        addSubview(allTableView)
        loadAllBlock()
    }
    
    private func loadAllBlock() {
        bottomView.confirmBtnBlock = { [weak self] in
            if let strongSelf = self {
                if let resetBlock = strongSelf.resetBtnBlock {
                    resetBlock(strongSelf.dataSourceType)
                }
                if let block = strongSelf.backBtnBlock {
                    block()
                }
            }
        }
        
        bottomView.resetBtnBlock = { [weak self] in
            if let strongSelf = self {
                strongSelf.selectedCategoryList.removeAll()
                strongSelf.selectedBrandList.removeAll()
                strongSelf.selectedMerchanList.removeAll()
                strongSelf.selectedColorList.removeAll()
                switch strongSelf.dataSourceType {
                case .category:
                    strongSelf.level2Categorylist.forEach({ (cat) in
                        cat.categoryList?.forEach({ (cat2) in
                            cat2.isSelected = false
                        })
                    })
                    strongSelf.allCollectionView.reloadData()
                    break
                case .brand:
                    strongSelf.selectedBrandList.removeAll()
                    strongSelf.brandList.forEach({ (brand) in
                        brand.isSelected = false
                    })
                    strongSelf.allTableView.reloadData()
                    break
                case .merchant:
                    strongSelf.selectedMerchanList.removeAll()
                    strongSelf.merchantList.forEach({ (merchant) in
                        merchant.isSelected = false
                    })
                    strongSelf.allTableView.reloadData()
                    break
                case .color:
                    strongSelf.selectedColorList.removeAll()
                    strongSelf.colorList.forEach({ (color) in
                        color.isSelected = false
                    })
                    strongSelf.allTableView.reloadData()
                    break
                default:
                    break
                }
                
                if let resetBlock = strongSelf.resetBtnBlock {
                    resetBlock(strongSelf.dataSourceType)
                }
            }
        }
        topView.backBtnBlock = { [weak self] in
            if let strongSelf = self {
                switch strongSelf.dataSourceType {
                case .category:
                    strongSelf.level2Categorylist.forEach({ (cat1) in
                        cat1.categoryList?.forEach({ (cat2) in
                            cat2.isSelected = false
                            if (strongSelf.selectedCategoryList.contains(where: {$0.categoryId == cat2.categoryId})) {
                                cat2.isSelected = true
                            }
                        })
                    })
                    break
                case .brand:
                    strongSelf.brandList.forEach({ (brand) in
                        brand.isSelected = false
                        if (strongSelf.selectedBrandList.contains(where: {$0.brandId == brand.brandId})) {
                            brand.isSelected = true
                        }
                    })
                    break
                case .merchant:
                    strongSelf.merchantList.forEach({ (merchant) in
                        merchant.isSelected = false
                        if (strongSelf.selectedMerchanList.contains(where: {$0.merchantId == merchant.merchantId})) {
                            merchant.isSelected = true
                        }
                    })
                    break
                case .color:
                    strongSelf.colorList.forEach({ (color) in
                        color.isSelected = false
                        if (strongSelf.selectedColorList.contains(where: {$0.colorId == color.colorId})) {
                            color.isSelected = true
                        }
                    })
                    break
                default:
                    break
                }
                
                if let block = strongSelf.backBtnBlock {
                    block()
                }
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var allCollectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.headerReferenceSize = CGSize(width: frame.width, height: 30)
        flowLayout.footerReferenceSize = CGSize(width: 0, height: 0)
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        flowLayout.sectionInset = UIEdgeInsetsMake(cellMargin, cellMargin, cellMargin, cellMargin)
        let collection = UICollectionView(frame: CGRect(x: 0, y: StartYPos, width: width, height: height - StartYPos - bottomView.height), collectionViewLayout: flowLayout)
        collection.backgroundColor = UIColor.white
        collection.showsVerticalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(MMFilterCollectionViewCell.self, forCellWithReuseIdentifier: "MMFilterCollectionViewCell")
        collection.register(UINib(nibName: "MMFilterCollectionHeaderView", bundle: Bundle.main), forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMFilterCollectionHeaderView")
        return collection
    }()
    
    private lazy var allTableView: UITableView = {
        let tb = UITableView(frame: CGRect(x: 0, y: StartYPos, width: width, height: height - StartYPos - bottomView.height), style: UITableViewStyle.plain)
        tb.dataSource = self
        tb.delegate = self
        tb.separatorStyle = .none
        tb.showsVerticalScrollIndicator = false
        tb.backgroundColor = UIColor.white
        tb.rowHeight = 34
        tb.sectionFooterHeight = 0.0
        tb.sectionHeaderHeight = 40
        tb.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        tb.register(MMFilterTableViewCell.self, forCellReuseIdentifier: "MMFilterTableViewCell")
        let configuration = SCIndexViewConfiguration(indexViewStyle: SCIndexViewStyle.none)
        configuration?.indexItemSelectedBackgroundColor = UIColor(hexString: "#FFFFFF")
        configuration?.indexItemSelectedTextColor = UIColor.darkGray
        configuration?.indexItemAllSelectTextColor = UIColor(hexString: "#ED2247")
        tb.sc_indexViewConfiguration = configuration
        return tb
    }()
    
    lazy var bottomView: MMBottomView = {
        let v = MMBottomView(frame: CGRect(x: 0, y: height - FilterBottomViewHeight - ScreenBottom, width: width, height: FilterBottomViewHeight + ScreenBottom))
        return v
    }()
    
    fileprivate lazy var topView: MMFilterTopView = {
        let v = MMFilterTopView(frame: CGRect(x: 0, y: 0, width: width, height: StartYPos))
        return v
    }()
}

extension MMFilterAllListView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let key = sectionTitles[indexPath.section]
        switch dataSourceType {
        case .brand:
            if let brand = brandDataList[key]?[indexPath.row] {
                brand.isSelected = !brand.isSelected
            }
            reloadBrandIndexView()
            break
        case .merchant:
            if let merchant = merchantDataList[key]?[indexPath.row] {
                merchant.isSelected = !merchant.isSelected
            }
            reloadMerchantIndexView()
            break
        default:
            break
        }
        
        allTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MMFilterTableViewCell", for: indexPath) as! MMFilterTableViewCell
        let key = sectionTitles[indexPath.section]
        switch dataSourceType {
        case .brand:
            if let brand = brandDataList[key]?[indexPath.row] {
                cell.contentLb.text = brand.brandName
                cell.selectedImageView.isHidden = !brand.isSelected
                cell.backContentView.backgroundColor = brand.isSelected ? UIColor(hexString: "#F5F5F5") : UIColor.white
            }
            break
        case .merchant:
            if let merchant = merchantDataList[key]?[indexPath.row] {
                cell.contentLb.text = merchant.merchantName
                cell.selectedImageView.isHidden = !merchant.isSelected
                cell.backContentView.backgroundColor = merchant.isSelected ? UIColor(hexString: "#F5F5F5") : UIColor.white
            }
            break
        default:
            break
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch dataSourceType {
        case .brand:
            let brands = brandDataList[sectionTitles[section]]
            return brands?.count ?? 0
        case .merchant:
            let merchants = merchantDataList[sectionTitles[section]]
            return merchants?.count ?? 0
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch dataSourceType {
        case .brand, .merchant:
            return sectionTitles.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.white
        let titleLabel = UILabel()
        titleLabel.text = sectionTitles[section]
        titleLabel.textColor = UIColor(hexString: "#333333")
        titleLabel.font = UIFont.fontWithSize(18, isBold: true)
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(headerView).offset(15)
            make.right.bottom.height.equalTo(headerView)
        }
        return headerView
    }
}

extension MMFilterAllListView: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch dataSourceType {
        case .category:
            let cat = level2Categorylist[indexPath.section].categoryList![indexPath.row]
            cat.isSelected = !cat.isSelected
            break
        case .color:
            let color = colorList[indexPath.row]
            color.isSelected = !color.isSelected
            break
        default:
            break
        }
        allCollectionView.reloadItems(at: [indexPath])
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch dataSourceType {
        case .category:
            return (level2Categorylist[section].categoryList?.count) ?? 0
        case .productTag:
            return 0
        case .color:
            return colorList.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        switch dataSourceType {
        case .category:
            return level2Categorylist.count
        case .productTag:
            return 1
        case .color:
            return 1
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MMFilterCollectionViewCell", for: indexPath) as! MMFilterCollectionViewCell
        switch dataSourceType {
        case .category:
            cell.colorImageView.isHidden = true
            let cat = level2Categorylist[indexPath.section].categoryList![indexPath.row]
            cell.titleLb.text = cat.categoryName
            cell.isSelectedCell = cat.isSelected
            break
        case .color:
            let color = colorList[indexPath.row]
            cell.colorImageView.isHidden = false
            cell.titleLb.isHidden = true
            cell.colorImageView.mm_setImageWithURL(
                ImageURLFactory.URLSize1000(color.colorImage, category: .color), placeholderImage: UIImage(named: "holder"))
            cell.isSelectedCell = color.isSelected
            break
        default:
            break
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "MMFilterCollectionHeaderView", for: indexPath) as! MMFilterCollectionHeaderView
        headerView.contentLb.text = ""
        headerView.arrowBtn.isHidden = true
        switch dataSourceType {
        case .category:
            let cat = level2Categorylist[indexPath.section]
            headerView.titleLb.text = cat.categoryName
            break
        case .color:
            headerView.titleLb.text = String.localize("LB_CA_FILTER_COLOR")
            break
        default:
            break
        }
        return headerView
    }
}

fileprivate class MMFilterTableViewCell: UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(backContentView)
        backContentView.addSubview(contentLb)
        backContentView.addSubview(selectedImageView)
        
        setNeedsUpdateConstraints()
    }
    
    override func updateConstraints() {
        backContentView.snp.makeConstraints { (make) in
            make.left.top.bottom.equalTo(contentView)
            make.right.equalTo(contentView.snp.right).offset(-25)
        }
        
        selectedImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 14, height: 10))
            make.right.equalTo(backContentView.snp.right).offset(-10)
            make.centerY.equalTo(backContentView.snp.centerY)
        }
        
        contentLb.snp.makeConstraints { (make) in
            make.bottom.top.equalTo(backContentView)
            make.left.equalTo(backContentView.snp.left).offset(15)
            make.right.equalTo(self.selectedImageView.snp.left)
        }
        super.updateConstraints()
    }
    
    lazy var backContentView: UIView = {
        let v = UIView()
        return v
    }()
    
    lazy var contentLb: UILabel = {
        let lb = UILabel()
        lb.textColor = UIColor(hexString: "#333333")
        lb.font = UIFont.systemFont(ofSize: 14)
        return lb
    }()
    
    lazy var selectedImageView: UIImageView = {
        let s = UIImageView(image: UIImage(named: "filte_chose"))
        return s
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

fileprivate class MMFilterTopView: UIView {
    
    public var backBtnBlock: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(backBtn)
        addSubview(topViewTitleLb)
        addSubview(line)
        setNeedsUpdateConstraints()
    }
    
    @objc private func backBtnClick() {
        if let block = backBtnBlock {
            block()
        }
    }
    
    override func updateConstraints() {
        backBtn.snp.makeConstraints { (make) in
            make.width.equalTo(40)
            make.left.equalTo(self.snp.left)
            make.bottom.equalTo(self.snp.bottom).offset(-13)
            make.height.equalTo(16)
        }
        topViewTitleLb.snp.makeConstraints { (make) in
            make.centerX.equalTo(self.snp.centerX)
            make.bottom.equalTo(self.snp.bottom).offset(-10)
            make.width.greaterThanOrEqualTo(30)
            make.height.equalTo(22)
        }
        line.snp.makeConstraints { (make) in
            make.bottom.left.right.equalTo(self)
            make.height.equalTo(0.5)
        }
        super.updateConstraints()
    }
    
    public lazy var topViewTitleLb: UILabel = {
        let lb = UILabel()
        lb.textAlignment = .center
        lb.font = UIFont.fontWithSize(16, isBold: true)
        lb.textColor = UIColor(hexString: "#333333")
        return lb
    }()
    
    private lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "back_arrow"), for: .normal)
        btn.addTarget(self, action: #selector(self.backBtnClick), for: UIControlEvents.touchUpInside)
        return btn
    }()
    
    private lazy var line: UILabel = {
        let line = UILabel()
        line.backgroundColor = UIColor(hexString: "#E7E7E7")
        return line
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

