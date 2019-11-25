//
//  StyleFilter.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 15/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class StyleFilter {
    var queryString: String = ""
    
    var priceFrom: Int?{
        didSet {
            self.updateFilterTagsByPriceRange()
        }
    }
    
    var priceTo: Int? {
        didSet {
            self.updateFilterTagsByPriceRange()
        }
    }

    var badges: [Badge] = []
    var brands: [Brand] = []
    var cats: [Cat] = []
    var colors: [Color] = []
    var sizes: [Size] = []
    var merchants: [Merchant] = []
    var sort: String = ""
    var order: String = ""
    var zone: String = ""
    
    var rootCategories: [Cat] = []
    
    var isNew = -1 {
        didSet {
            if isNew == 1 {
                if (filterTags.filter{$0.filterType == .newProduct}).count == 0 {
                    self.addTag(withFilterType: .newProduct)
                }
            } else {
                if let filterTag = (filterTags.filter{$0.filterType == .newProduct}).first {
                    filterTags.remove(filterTag)
                }
            }
        }
    }
    
    var isSale = -1 {
        didSet {
            if isSale == 1 {
                if (filterTags.filter{$0.filterType == .sale}).count == 0 {
                    self.addTag(withFilterType: .sale)
                }
            } else {
                if let filterTag = (filterTags.filter{$0.filterType == .sale}).first {
                    filterTags.remove(filterTag)
                }
            }
        }
    }
    
    var isCrossBorder = -1 {
        didSet {
            if isCrossBorder == 1 {
                if (filterTags.filter{$0.filterType == .crossBorder}).count == 0 {
                    self.addTag(withFilterType: .crossBorder)
                }
            } else {
                if let filterTag = (filterTags.filter{$0.filterType == .crossBorder}).first {
                    filterTags.remove(filterTag)
                }
            }
        }
    }

    var isFilter = false
    var filterTags: [FilterTag] = []{
        didSet{
            if let action = filterTagsObserver{
                action()
            }
        }
    }
    
    var filterTagsObserver: (()->())?
    
    func count() -> Int {
        return badges.count + brands.count + cats.count + colors.count + sizes.count + merchants.count + priceCount() + newCount() + saleCount() + crossBorderCount()
    }
    
    func priceCount() -> Int {
        if (priceFrom != nil) || (priceTo != nil){
            return 1
        }
        return 0
    }
    
    func getFormattedPriceRange() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        
        var priceFromText = String.localize("LB_CA_LOWEST_PRICE")
        if let priceFrom = self.priceFrom, let symbol = formatter.currencySymbol {
            priceFromText = "\(symbol) \(priceFrom)"
        } else if let _ = self.priceTo, let symbol = formatter.currencySymbol {
            priceFromText = "\(symbol) 0"
        }
        
        var priceToText = String.localize("LB_CA_HIGHEST_PRICE")
        if let priceTo = self.priceTo, let symbol = formatter.currencySymbol {
            priceToText = "\(symbol) \(priceTo)"
        }

        return "\(priceFromText) - \(priceToText)"
    }
    
    func newCount() -> Int {
        if isNew == 1 {
            return 1
        }
        return 0
    }
    
    func saleCount() -> Int {
        if isSale == 1 {
            return 1
        }
        return 0
    }

    func crossBorderCount() -> Int {
        if isCrossBorder == 1 {
            return 1
        }
        return 0
    }
    
    private static var snapshotInstance: StyleFilter = StyleFilter() {
        didSet {
            Log.debug("StyleFilter snapshotInstance did set :\(snapshotInstance)")
        }
    }
    
    func saveSnapshot() {
        StyleFilter.snapshotInstance = self.clone()
    }
    
    static func getSnapshot() -> StyleFilter {
        return snapshotInstance.clone()
    }
    
    func reset() {
        queryString = ""
        priceFrom = 0
        priceTo = 10000
        badges = []
        brands = []
        cats = []
        colors = []
        sizes = []
        merchants = []
        sort = ""
        order = ""
        isNew = -1
        isSale = -1
        isCrossBorder = -1
        isFilter = false
    }
    
    func clone()-> StyleFilter {
        let styleFilter = StyleFilter()
        styleFilter.queryString = queryString
        styleFilter.priceFrom = priceFrom
        styleFilter.priceTo = priceTo
        
        for badge in badges {
            styleFilter.badges.append(badge)
        }
        
        for brand in brands {
            styleFilter.brands.append(brand)
        }
        
        for cat in cats {
            styleFilter.cats.append(cat)
        }
        
        for color in colors {
            styleFilter.colors.append(color)
        }
        
        for size in sizes {
            styleFilter.sizes.append(size)
        }
        
        for merchant in merchants {
            styleFilter.merchants.append(merchant)
        }
        
        for cat in rootCategories {
            styleFilter.rootCategories.append(cat)
        }
        
        styleFilter.sort = sort
        styleFilter.order = order
        styleFilter.zone = zone
        styleFilter.isNew = isNew
        styleFilter.isSale = isSale
        styleFilter.isCrossBorder = isCrossBorder
        styleFilter.isFilter = isFilter
        
        styleFilter.filterTags = filterTags

        return styleFilter
    }
    
    var description: String {
        var priceFromText = ""
        if let priceFrom = self.priceFrom{
            priceFromText = "\(priceFrom)"
        }
        
        var priceToText = ""
        if let priceTo = self.priceTo{
            priceToText = "\(priceTo)"
        }
        
        return "queryString = \(queryString) pricefrom = \(priceFromText) priceto = \(priceToText) badges = \(badges) brands=\(brands) cats=\(cats) colors=\(colors) sizes = \(sizes) merchants = \(merchants) sort = \(sort) order = \(order) isnew = \(isNew) issale = \(isSale) iscrossborder = \(isCrossBorder) isFilter =\(isFilter)"
    }

    func removeNestedCategory(_ cat: Cat) {
        removeCategory(cat.categoryId)
        if let list = cat.categoryList {
            for cat in list {
                removeCategory(cat.categoryId)
            }
        }
    }
    
    func removeCategory(_ categoryId: Int) {
        for cat in self.cats   {
            if cat.categoryId == categoryId {
                self.removeTag(cat.categoryId, filterType: .category)
                self.cats.remove(cat)
            }
        }
    }
    
    func updateSubFilterName(_ subFilterItem: Any) {
        if let badge = subFilterItem as? Badge{
            if let filterBadge = (self.badges.filter{$0.badgeId == badge.badgeId}  ).first{
                filterBadge.badgeName = badge.badgeName
            }
        }
        else if let brand = subFilterItem as? Brand{
            if let filterBrand = (self.brands.filter{$0.brandId == brand.brandId}  ).first{
                filterBrand.brandName = brand.brandName
            }
        }
        else if let cat = subFilterItem as? Cat{
            if let filterCat = (self.cats.filter{$0.categoryId == cat.categoryId}  ).first{
                filterCat.categoryName = cat.categoryName
            }
        }
        else if let size = subFilterItem as? Size{
            if let filterSize = (self.sizes.filter{$0.sizeId == size.sizeId}  ).first{
                filterSize.sizeName = size.sizeName
            }
        }
        else if let color = subFilterItem as? Color{
            if let filterColor = (self.colors.filter{$0.colorId == color.colorId}  ).first{
                filterColor.colorName = color.colorName
            }
        }
        else if let merchant = subFilterItem as? Merchant{
            if let filterMerchant = (self.merchants.filter{$0.merchantId == merchant.merchantId}  ).first{
                filterMerchant.merchantName = merchant.merchantName
            }
        }
    }
    
    func hasCategory(_ categoryId: Int) -> Bool{
        return (((self.cats.filter{$0.categoryId == categoryId})  ).count > 0)
    }
    
    func hasBrand(_ brandId: Int) -> Bool{
        return (((self.brands.filter{$0.brandId == brandId})  ).count > 0)
    }
    
    func hasColor(_ colorId: Int) -> Bool{
        return (((self.colors.filter{$0.colorId == colorId})  ).count > 0)
    }
    
    func hasSize(_ sizeId: Int) -> Bool{
        return (((self.sizes.filter{$0.sizeId == sizeId})  ).count > 0)
    }
    
    func hasMerchant(_ merchantId: Int) -> Bool{
        return (((self.merchants.filter{$0.merchantId == merchantId})  ).count > 0)
    }
    
    func initFilterTags() {
        filterTags = []
        
        if self.isNew == 1 {
            self.addTag(withFilterType: .newProduct, isRemovable: false)
        }
        
        if self.isSale == 1 {
            self.addTag(withFilterType: .sale, isRemovable: false)
        }
        
        if self.isCrossBorder == 1 {
            self.addTag(withFilterType: .crossBorder, isRemovable: false)
        }
        
        if let badges = self.badges as [Badge]? {
            for badge in badges {
                self.addTag(badge.badgeName, id: badge.badgeId, filterType: .badge, isRemovable: false)
            }
        }
        
        self.updateFilterTagsByPriceRange(isRemovable: false)
        
        if let brands = self.brands as [Brand]? {
            for brand in brands {
                self.addTag(brand.brandName, id: brand.brandId, filterType: .brand, isRemovable: false)
            }
        }
        
        if let cats = self.cats as [Cat]? {
            for cat in cats {
                self.addTag(cat.categoryName, id: cat.categoryId, filterType: .category, isRemovable: false)
            }
        }
        
        if let colors = self.colors as [Color]? {
            for color in colors {
                self.addTag(color.colorName, id: color.colorId, filterType: .color, isRemovable: false)
            }
        }
        
        if let sizes = self.sizes as [Size]? {
            for size in sizes {
                self.addTag(size.sizeName, id: size.sizeId, filterType: .size, isRemovable: false)
            }
        }
        
        if let merchants = self.merchants as [Merchant]? {
            for merchant in merchants {
                self.addTag(merchant.merchantName, id: merchant.merchantId, filterType: .merchant, isRemovable: false)
            }
        }
    }
    
    func removeEmptyNameFilterTags(){
        for filterTag in filterTags{
            if (filterTag.name ?? "").isEmpty{
                self.removeTag(filterTag.id, filterType: filterTag.filterType)
            }
        }
    }
    
    private func updateFilterTagsByPriceRange(isRemovable: Bool = true) {
        if let filterTag = (filterTags.filter{$0.filterType == .priceRange}).first {
            if priceCount() == 1{
                filterTag.name = self.getFormattedPriceRange()
            }else{
                self.removeTag(filterTag.id, filterType: filterTag.filterType)
            }
        } else {
            if priceCount() == 1{
                self.addTag(self.getFormattedPriceRange(), id: 0, filterType: .priceRange, isRemovable: isRemovable)
            }
        }
    }
    
    func addTag(_ name: String, id: Int, filterType: FilterType, isRemovable: Bool = true) {
        let filterTag = FilterTag(name: name,id : id, filterType: filterType)
        filterTag.isRemovable = isRemovable
        
        switch filterType {
        case FilterType.category:
            if id != DiscoverCategoryViewController.AllCategory{
                filterTags.append(filterTag)
            }
        default:
            filterTags.append(filterTag)
        }
    }
    
    func addTag(withFilterType filterType: FilterType, isRemovable: Bool = true) {
        var name = ""
        
        switch filterType {
        case .newProduct:
            name = String.localize("LB_CA_NEW_PRODUCT_SHORT")
        case .sale:
            name = String.localize("LB_CA_DISCOUNT")
        case .crossBorder:
            name = String.localize("LB_OVERSEAS")
        default:
            break
        }
        
        if name.length > 0 {
            self.addTag(name, id: 0, filterType: filterType, isRemovable: isRemovable)
        }
    }
    
    func removeTag(_ id: Int, filterType: FilterType) {
        let tags = filterTags.filter{$0.filterType == filterType}
        
        for tag in tags {
            if id == tag.id {
                filterTags.remove(tag)
            }
        }
    }
    
    func removeTag(_ filterTag: FilterTag) {
        self.removeTag(filterTag.id, filterType: filterTag.filterType)
    }
    
    func updateFilterTags(aggregations: Aggregations){
        for filtertag in self.filterTags{
            if !filtertag.isRemovable{
                continue
            }
            switch filtertag.filterType {
            case .badge:
                filtertag.isEnable = aggregations.badgeArray.contains(filtertag.id)
            case .brand:
                filtertag.isEnable = aggregations.brandArray.contains(filtertag.id)
            case .category:
                filtertag.isEnable = aggregations.categoryArray.contains(filtertag.id)
            case .color:
                filtertag.isEnable = aggregations.colorArray.contains(filtertag.id)
            case .size:
                filtertag.isEnable = aggregations.sizeArray.contains(filtertag.id)
            case .merchant:
                filtertag.isEnable = aggregations.merchantArray.contains(filtertag.id)
            default:
                break
            }
        }
    }
    
    func updateSubFilter(_ filterTag: FilterTag){
        
    }
    
    func equal(_ styleFilter: StyleFilter) -> Bool{
        if self.isNew != styleFilter.isNew ||
            self.isSale != styleFilter.isSale ||
            self.isCrossBorder != styleFilter.isCrossBorder ||
            self.priceTo != styleFilter.priceTo ||
            self.priceFrom != styleFilter.priceFrom {
            return false
        }
        
        if self.brands.count != styleFilter.brands.count{
            return false
        }
        else{
            let filteredItems = self.brands.filter{styleFilter.hasBrand($0.brandId)}
            if filteredItems.count != styleFilter.brands.count{
                return false
            }
        }
        
        if self.cats.count != styleFilter.cats.count{
            return false
        }
        else{
            let filteredItems = self.cats.filter{styleFilter.hasCategory($0.categoryId)}
            if filteredItems.count != styleFilter.cats.count{
                return false
            }
        }
        
        if self.colors.count != styleFilter.colors.count{
            return false
        }
        else{
            let filteredItems = self.colors.filter{styleFilter.hasColor($0.colorId)}
            if filteredItems.count != styleFilter.colors.count{
                return false
            }
        }
        
        if self.sizes.count != styleFilter.sizes.count{
            return false
        }
        else{
            let filteredItems = self.sizes.filter{styleFilter.hasSize($0.sizeId)}
            if filteredItems.count != styleFilter.sizes.count{
                return false
            }
        }
        
        if self.merchants.count != styleFilter.merchants.count{
            return false
        }
        else{
            let filteredItems = self.merchants.filter{styleFilter.hasMerchant($0.merchantId)}
            if filteredItems.count != styleFilter.merchants.count{
                return false
            }
        }
        
        return true
    }
    
    static func createLinkSytleFilter(ssn_Arguments : QBundle,completion: @escaping (_ hasFilter:Bool,_ styleFilter:StyleFilter) -> Void) {
        let keys = ssn_Arguments.keys
        
        let styleFilter = StyleFilter()
        var hasFilter = false
        for keyValue in keys {
            if let strongValue = ssn_Arguments[keyValue]?.string {
                if strongValue.trim().length == 0{
                    continue
                }
                
                if let strongKey:DeepLinkManager.ProductListFilter = DeepLinkManager.ProductListFilter(rawValue: keyValue){
                    switch strongKey {
                    case .ProductListFilterColor:
                        hasFilter = true
                        let colorStrings = strongValue.components(separatedBy: ",")
                        //create color array
                        var colors = [Color]()
                        //add color to array
                        for colorId in colorStrings {
                            if let strongColorId = Int(colorId){
                                let colorModel = Color()
                                colorModel.colorId = strongColorId
                                colors.append(colorModel)
                            }
                        }
                        styleFilter.colors = colors
                    case .ProductListFilterSize:
                        hasFilter = true
                        let sizeStrings = strongValue.components(separatedBy: ",")
                        //create size array
                        var sizes = [Size]()
                        //add size to array
                        for sizeId in sizeStrings {
                            if let strongSizeId = Int(sizeId){
                                let sizeModel = Size()
                                sizeModel.sizeId = strongSizeId
                                sizes.append(sizeModel)
                            }
                        }
                        styleFilter.sizes = sizes
                    case .ProductListFilterKeyword, .ProductListFilterS:
                        hasFilter = true
                        styleFilter.queryString = strongValue
                    case .ProductListFilterCategory:
                        hasFilter = true
                        let catStrings = strongValue.components(separatedBy: ",")
                        //create cat array
                        var ids = [Int]()
                        //add cat to array
                        var cats = [Cat]()
                        
                        for catId in catStrings {
                            if let strongCatId = Int(catId) {
                                ids.append(strongCatId)
                                //从缓存取数据比较可靠
                                let cat = CacheManager.sharedManager.cachedCategoryById(strongCatId) ?? Cat()
                                cat.categoryId = strongCatId
                                cats.append(cat)
                            }
                        }
                        
                        styleFilter.cats = cats
                        styleFilter.rootCategories = cats
                        
                        
                    case .ProductListFilterBrand:
                        hasFilter = true
                        let brandStrings = strongValue.components(separatedBy: ",")
                        //create brand array
                        var brands = [Brand]()
                        
                        //add brand to array
                        for brandId in brandStrings {
                            if let strongBrandId = Int(brandId){
                                let brandModel = CacheManager.sharedManager.cachedBrandById(strongBrandId) ?? Brand()
                                brandModel.brandId = strongBrandId
                                brands.append(brandModel)
                            }
                        }
                        styleFilter.brands = brands
                        
                    case .ProductListFilterMerchant:
                        hasFilter = true
                        let merchantIds = strongValue.components(separatedBy: ",")
                        //create brand array
                        var merchants = [Merchant]()
                        
                        //add brand to array
                        for merchantId in merchantIds {
                            if let mId = Int(merchantId){
                                let merchant = CacheManager.sharedManager.cachedMerchantById(mId) ?? Merchant()
                                merchant.merchantId = mId
                                merchants.append(merchant)
                            }
                        }
                        styleFilter.merchants = merchants
                        
                    case .ProductListFilterPriceFrom:
                        hasFilter = true
                        if let priceFromInt = Int(strongValue){
                            styleFilter.priceFrom = priceFromInt
                        }
                        
                    case .ProductListFilterPriceTo:
                        if let priceToInt = Int(strongValue){
                            styleFilter.priceTo = priceToInt
                        }
                    case .ProductListFilterBadge:
                        hasFilter = true
                        let badgeStrings = strongValue.components(separatedBy: ",")
                        //create badge array
                        var badges = [Badge]()
                        //add brand to array
                        for badgeId in badgeStrings {
                            if let strongBadgeId = Int(badgeId){
                                let badgeModel = Badge()
                                badgeModel.badgeId = strongBadgeId
                                badges.append(badgeModel)
                            }
                        }
                        styleFilter.badges = badges
                    case .ProductListFilterCrossborder:
                        hasFilter = true
                        if let isCrossBorder = Int(strongValue){
                            styleFilter.isCrossBorder = isCrossBorder
                        }
                    case .ProductListFilterSale:
                        hasFilter = true
                        if let isSale = Int(strongValue){
                            styleFilter.isSale = isSale
                        }
                    case .ProductListFilterZone:
                        hasFilter = true
                        if !styleFilter.zone.isEmpty{
                            styleFilter.zone = ""
                        }
                        else{
                            styleFilter.zone = strongValue
                        }
                    case .ProductListFilterSort:
                        hasFilter = true
                        styleFilter.sort = strongValue
                    case .ProductListFilterOrder:
                        hasFilter = true
                        styleFilter.order = strongValue
                    }
                }
            }
        }
        
        completion(hasFilter,styleFilter)
    }
}
