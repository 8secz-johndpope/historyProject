//
//  MMFilterViewController.swift
//  storefront-ios
//
//  Created by Demon on 19/7/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit

private let FilterCollectionViewRatio: CGFloat = 0.8
let FilterBottomViewHeight: CGFloat = 50

class MMFilterViewController: MMUIController {
    
    public var selectedfilterGenderType: MMFilterGenderType = .unKnow
    var aggregations: Aggregations? // 需要展示的id集合
    var originStyleFilter: StyleFilter = StyleFilter() // 原始的数据 不做改变 只做展示
    var userStyleFilter: StyleFilter = StyleFilter() // 用户的选择行为数据 浅拷贝特点,值已经在上级界面发生改变
    var styles: [Style] = [Style]() // 不知道这个是干嘛用的 之前老逻辑有这个属性
    weak var filterViewControllerDelegate: FilterStyleDelegate?
    var confirmBlock:((_ filterGenderType: MMFilterGenderType) -> ())?
    
    private var isMale: Bool { // 判断当前搜索关键字中是否包含"男"字
        get {
                if originStyleFilter.queryString.length > 0 {
                    return originStyleFilter.queryString.contain(String.localize("LB_CA_GENDER_M"))
                }
            return false
        }
    }
    
    override func onViewDidAppear(_ animated: Bool) {
        beginFilterCollectionViewAnimation()
    }

    override func onViewDidLoad() {
        //固定埋点配置
        self._node = VCNode()
        self._node.url = "https://m.mymm.com/l/filter"
        self.ssn_uri = "l/filter"
        self.track_pageUrl = self._node.url
        
        super.onViewDidLoad()
        
        self.automaticallyAdjustsScrollViewInsets = false
        
        view.backgroundColor = UIColor(hexString: "#333333").withAlphaComponent(0.5)
        view.tag = 1100
        view.addSubview(filterCollectionView)
        filterCollectionView.selectedGenderType = selectedfilterGenderType
        filterCollectionView.aggregations = aggregations ?? Aggregations()
        
        loadBrandList()
        loadBadgeList()
        loadCategories()
        loadMerchant()
        loadColorList()
        
        filterCollectionView.priceRange = (self.userStyleFilter.priceFrom,self.userStyleFilter.priceTo)
        
        filterCollectionView.bottomView.resetBtnBlock = { [weak self] in
            if let strongSelf = self {
                strongSelf.resetBtnClick()
            }
        }
        filterCollectionView.bottomView.confirmBtnBlock = { [weak self] in
            if let strongSelf = self {
                strongSelf.confirmBtnClick()
            }
        }
    }
    
    private func confirmBtnClick() {
        let filter = filterCollectionView.confirmAllFilterData()
        userStyleFilter.reset()
        originStyleFilter.priceFrom = filter.minPrice
        originStyleFilter.priceTo = filter.maxPrice
        
        userStyleFilter.priceFrom = filter.minPrice
        userStyleFilter.priceTo = filter.maxPrice
        
        if (filter.selectedCategoryList?.count)! > 0 { // 用户有选择条件就覆盖原始的筛选条件,
            originStyleFilter.cats.removeAll()
            userStyleFilter.cats.removeAll()
            filter.selectedCategoryList?.forEach({ (cat) in
                originStyleFilter.cats.append(cat)
                userStyleFilter.cats.append(cat)
            })
        }
        if (filter.selectedBrandList?.count)! > 0 {
            originStyleFilter.brands.removeAll()
            userStyleFilter.brands.removeAll()
            filter.selectedBrandList?.forEach({ (brand) in
                originStyleFilter.brands.append(brand)
                userStyleFilter.brands.append(brand)
            })
        }
        if (filter.selectedMerchantList?.count)! > 0 {
            originStyleFilter.merchants.removeAll()
            userStyleFilter.merchants.removeAll()
            filter.selectedMerchantList?.forEach({ (merchant) in
                originStyleFilter.merchants.append(merchant)
                userStyleFilter.merchants.append(merchant)
            })
        }
        if (filter.selectedProductTagList?.count)! > 0 {
            for badge in filter.selectedProductTagList! {
                if badge.badgeId != MMFilterBadgeType.discount.rawValue && badge.badgeId != MMFilterBadgeType.overSeas.rawValue {
                    originStyleFilter.badges.removeAll()
                    userStyleFilter.badges.removeAll()
                }
            }
            filter.selectedProductTagList?.forEach({ (badge) in
                if badge.badgeId == MMFilterBadgeType.discount.rawValue {
                    originStyleFilter.isSale = 1
                    userStyleFilter.isSale = 1
                } else if badge.badgeId == MMFilterBadgeType.overSeas.rawValue {
                    originStyleFilter.isCrossBorder = 1
                    userStyleFilter.isCrossBorder = 1
                } else {
                    originStyleFilter.badges.append(badge)
                    userStyleFilter.badges.append(badge)                    
                }
                
            })
        }
        if ((filter.selectedColorList?.count)! > 0) {
            originStyleFilter.colors.removeAll()
            userStyleFilter.colors.removeAll()
            filter.selectedColorList?.forEach({ (color) in
                originStyleFilter.colors.append(color)
                userStyleFilter.colors.append(color)
            })
        }

        if let delegate = filterViewControllerDelegate {
            delegate.filterStyle(styles, styleFilter: originStyleFilter, selectedFilterCategories: nil)
        }
        if let confirm = confirmBlock {
            confirm(filterCollectionView.selectedGenderType)
        }
        endFilterCollectionViewAnimation()
    }
    
    private func resetBtnClick() {
        filterCollectionView.resetAllFilterData()
    }
    
    private lazy var filterCollectionView: MMFilterCollectionView = {
        let cl = MMFilterCollectionView(frame: CGRect(x: ScreenWidth, y: 0, width: ScreenWidth * FilterCollectionViewRatio, height: ScreenHeight))
        cl.backgroundColor = UIColor.white
        return cl
    }()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if touch.view?.tag == 1100 {
                endFilterCollectionViewAnimation()
            }
        }
    }
    
    deinit {
        print("deinit MMFilterViewController")
    }

    override func onReceiveMemoryWarning() {
        
    }
}

extension MMFilterViewController {
    
    private func loadBadgeList() { // 产品标签
        SearchService.searchBadge() { [weak self] (response) in
            if let strongSelf = self {
                if response.result.isSuccess {
                    let badgeArray = Mapper<Badge>().mapArray(JSONObject: response.result.value) ?? []
                    var badges = badgeArray.filter({($0.badgeId != 0) && (strongSelf.aggregations?.badgeArray.contains($0.badgeId))!})
                    badges.forEach({ (badge) in
                        if strongSelf.userStyleFilter.badges.contains(where: {$0.badgeId == badge.badgeId}) {
                            badge.isSelected = true // 因为浅拷贝的原因,值的改变都存在缓存池中
                        } else {
                            badge.isSelected = false
                        }
                    })
                    let discount = Badge()
                    discount.badgeName = String.localize("LB_CA_DISCOUNT")
                    discount.isSelected = strongSelf.userStyleFilter.isSale == 1 ? true : false
                    discount.badgeId = MMFilterBadgeType.discount.rawValue
                    
                    let overSeas = Badge()
                    overSeas.badgeName = String.localize("LB_CA_BADGE_XBORDER")
                    overSeas.isSelected = strongSelf.userStyleFilter.isCrossBorder == 1 ? true : false
                    overSeas.badgeId = MMFilterBadgeType.overSeas.rawValue
                    
                    badges.insert(discount, at: 0)
                    badges.insert(overSeas, at: 0)

                    strongSelf.filterCollectionView.productTagbadgeList = badges
                }
            }
        }
    }
    
    private func loadCategories() { // 品类
        CacheManager.sharedManager.fetchAllCategories(completion: { [weak self] (cats, nextPage, error) in
            if let strongSelf = self {
                var level2Cats = [Cat]()
                for cat in cats ?? [] {
                    if let cats = cat.categoryList {
                        level2Cats.append(contentsOf: cats)
                    }
                }
                var filterCats = level2Cats.filter({$0.categoryId != 0 && $0.categoryId != -1})
                if let aggregation = strongSelf.aggregations {
                    filterCats = filterCats.filter({(aggregation.categoryArray.contains($0.categoryId)) && $0.statusId == 2})
                    filterCats.forEach({ (filterCat) in
                        filterCat.categoryList = (filterCat.categoryList ?? [])
                            .filter({(aggregation.categoryArray.contains($0.categoryId)) && $0.statusId == 2})
                    })
                    
                    var females = filterCats.filter({$0.isFemale == 1 && $0.isMale == 0})
                    females = strongSelf.reSortCategory(females, aggregation: aggregation)
                    var males = filterCats.filter({$0.isFemale == 0 && $0.isMale == 1})
                    males = strongSelf.reSortCategory(males, aggregation: aggregation)
                    
                    var nosexs = filterCats.filter({($0.isFemale == 1 && $0.isMale == 1) || ($0.isFemale == 0 && $0.isMale == 0)})
                    nosexs = strongSelf.reSortCategory(nosexs, aggregation: aggregation)
                    
                    if strongSelf.isMale {
                        filterCats = males + females + nosexs
                    } else {
                        filterCats = females + males + nosexs
                    }
                }
                
                filterCats.forEach({ (filterCat) in
                    filterCat.categoryList?.forEach({ (level3Cat) in
                        if strongSelf.userStyleFilter.cats.contains(where: {($0.categoryId == level3Cat.categoryId) && $0.isSelected == true}) {
                            level3Cat.isSelected = true // 因为浅拷贝的原因,值的改变都存在缓存池中
                        } else {
                            level3Cat.isSelected = false
                        }
                    })
                })
                strongSelf.filterCollectionView.Level2CategoryList = filterCats
            }
        })
    }
    
    private func reSortCategory(_ genderList: [Cat], aggregation: Aggregations) -> [Cat] {
        var newFemales: [Cat] = []
        for categoryId in aggregation.categoryArray {
            for cat in genderList {
                if cat.categoryId == categoryId {
                    newFemales.append(cat)
                    break
                }
            }
        }
        for newFemale in newFemales {
            var level3Cats: [Cat] = []
            for categoryId in aggregation.categoryArray {
                for cat in newFemale.categoryList! {
                    if cat.categoryId == categoryId {
                        level3Cats.append(cat)
                        break
                    }
                }
            }
            newFemale.categoryList = level3Cats
        }
        return newFemales
    }
    
    private func loadMerchant() {
        firstly {
            return MerchantService.fetchMerchantsIfNeeded(.all)
            }.then { merchants -> Void in
                var filteredMerchants = merchants.filter({$0.merchantId != 0})
                if let strongAggregation = self.aggregations {
                    var merchants: [Merchant] = []
                    for merchantId in strongAggregation.merchantArray { // 展示顺序和aggregations的顺序相同
                        for merchant in filteredMerchants {
                            if merchantId == merchant.merchantId {
                                merchants.append(merchant)
                                break
                            }
                        }
                    }
                    filteredMerchants = merchants
                }
                
                filteredMerchants.forEach({ (merchant) in
                    merchant.isSelected = false // 因为浅拷贝的原因,值的改变都存在缓存池中
                    if self.userStyleFilter.merchants.contains(where: {$0.merchantId == merchant.merchantId}) {
                        merchant.isSelected = true
                    }
                })
                self.filterCollectionView.merchantList = filteredMerchants
        }
    }
    
    private func loadColorList() {
        SearchService.searchColor { (response) in
            if response.result.isSuccess {
                var colors = Mapper<Color>().mapArray(JSONObject: response.result.value) ?? []
                colors = colors.filter({$0.colorId != 0 && $0.colorId != 1})
                colors = colors.sorted(by: {$0.colorId < $1.colorId})
                if let strongAggregation = self.aggregations {
                    colors = colors.filter({strongAggregation.colorArray.contains($0.colorId)})
                }
                
                colors.forEach({ (color) in
                    if self.userStyleFilter.colors.contains(where: {$0.colorId == color.colorId}) {
                        color.isSelected = true // 因为浅拷贝的原因,值的改变都存在缓存池中
                    } else {
                        color.isSelected = false
                    }
                })
                
                let redList = colors.filter({$0.colorId == 2})
                let blackList = colors.filter({$0.colorId == 12})
                let whiteList = colors.filter({$0.colorId == 11})
                
                if redList.count > 0 {
                    colors.remove(redList.first!)
                    colors.insert(redList.first!, at: 0)
                }
                if whiteList.count > 0 {
                    colors.remove(whiteList.first!)
                    colors.insert(whiteList.first!, at: 0)
                }
                if blackList.count > 0 {
                    colors.remove(blackList.first!)
                    colors.insert(blackList.first!, at: 0)
                }
                self.filterCollectionView.colorList = colors
            }
        }
    }
    
    private func loadBrandList() {
        BrandService.fetchAllBrandsIfNeeded(.red, sort: .BrandName, order: .orderedAscending).then { (brands) -> Void in
            DispatchQueue.global().async {
                var brandList = brands.filter({$0.brandId != 0})
                if let strongAggregation = self.aggregations {
                    var tBrandList: [Brand] = []
                    for brandId in strongAggregation.brandArray { // 展示顺序和aggregations的顺序相同
                        for brand in brandList {
                            if brandId == brand.brandId {
                                tBrandList.append(brand)
                                break
                            }
                        }
                    }
                    brandList = tBrandList
                }
                brandList.forEach({ (brand) in
                    if self.userStyleFilter.brands.contains(where: {$0.brandId == brand.brandId}) {
                        brand.isSelected = true // 因为浅拷贝的原因,值的改变都存在缓存池中
                    } else {
                        brand.isSelected = false
                    }
                })
                DispatchQueue.main.async {
                    self.filterCollectionView.brandList = brandList
                }
            }
        }
    }
}

extension MMFilterViewController {
    
    private func beginFilterCollectionViewAnimation() {
        UIView.animate(withDuration: 0.3) {
            self.filterCollectionView.x = (1 - FilterCollectionViewRatio)*ScreenWidth
        }
    }
    
    private func endFilterCollectionViewAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            self.filterCollectionView.x = ScreenWidth
        }) { (completion) in
            self.dismiss(animated: false, completion: nil)
        }
    }
}

class MMBottomView: UIView {
    
    var resetBtnBlock: (() -> ())?
    var confirmBtnBlock: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        addSubview(resetBtn)
        addSubview(confirmBtn)
    }
    
    @objc private func resetBtnClick() {
        if let resetBlock = resetBtnBlock {
            resetBlock()
        }
    }
    
    @objc private func confirmBtnClick() {
        if let confirmBlock = confirmBtnBlock {
            confirmBlock()
        }
    }
    
    private lazy var resetBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(String.localize("LB_RESET"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn.backgroundColor = UIColor.white
        btn.setTitleColor(UIColor(hexString: "#6B6B6B "), for: UIControlState.normal)
        btn.frame = CGRect(x: 0, y: 0, width: self.width/2.0, height: FilterBottomViewHeight)
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.05
        btn.layer.shadowOffset = CGSize(width: 0, height: -2)
        btn.addTarget(self, action: #selector(self.resetBtnClick), for: UIControlEvents.touchUpInside)
        return btn
    }()
    
    private lazy var confirmBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(String.localize("LB_OK"), for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn.setTitleColor(UIColor.white, for: UIControlState.normal)
        btn.frame = CGRect(x: resetBtn.frame.maxX, y: resetBtn.y, width: resetBtn.width, height: FilterBottomViewHeight)
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOpacity = 0.1
        btn.layer.shadowOffset = CGSize(width: 0, height: -2)
        let gradientlayer = CAGradientLayer()
        gradientlayer.colors = [UIColor(hexString: "#F7477D").cgColor,UIColor(hexString: "#ED2247").cgColor]
        gradientlayer.locations = [0.5,1.0]
        gradientlayer.startPoint = CGPoint(x: 0, y: 0)
        gradientlayer.endPoint = CGPoint(x: 1.0, y: 0)
        gradientlayer.frame = btn.bounds
        btn.layer.insertSublayer(gradientlayer, at: 0)
        btn.addTarget(self, action: #selector(self.confirmBtnClick), for: UIControlEvents.touchUpInside)
        return btn
    }()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
