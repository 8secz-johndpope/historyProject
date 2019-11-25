//
//  Style.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 27/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
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


class Style: Mappable, Equatable {
    public var vid: String = ""
    
    static func ==(lhs: Style, rhs: Style) -> Bool {
        return lhs.styleId == lhs.styleId
    }
    
    var styleId = 0
    var styleCode = ""
    var merchantId = 0
    var merchantCode = ""
    var imageDefault = ""
    var priceRetail: Double = 0
    var priceSale: Double = 0
    var saleFrom: Date?
    var saleTo: Date?
    var lastCreated = ""
    var availableFrom: Date?
    var availableTo: Date?
    var manufacturerName = ""
    var launchYear = ""
    var brandId = 0
    var brandStatusId = 0
    var brandName = ""
    var brandNameInvariant = ""
    var brandHeaderLogoImage = ""
    var brandSmallLogoImage = ""
    var skuName = ""
    var skuNameInvariant = ""
    var skuDesc = ""
    var skuDescInvariant = ""
    var skuFeature = ""
    var skuFeatureInvariant = ""
    var primaryCategoryId = 0
    var statusId = 0
    var statusName = ""
    var statusNameInvariant = ""
    var seasonId = 0
    var seasonName = ""
    var seasonNameInvariant = ""
    var badgeId = 0
    var badgeName = ""
    var badgeImage = ""
    var badgeNameInvariant = ""
    var geoCountryId = 0
    var geoCountryName = ""
    var geoCountryNameInvariant = ""
    var primarySkuId = 0
    var isNew = 0
    var isSale = 0
    var primaryCategoryPathList: [Cat] = []
    var sizeList: [Size] = []
    var colorList: [Color] = []
    var featuredImageList: [Img] = []
    var descriptionImageList: [Img] = []
    var colorImageList: [Img] = []
    var skuList: [Sku] = []
    var totalLocationCount = 0
    var categoryPriorityList: [Cat]?
    var isCrossBorder = false  // 是否海外
    var isDiscount = false
    var merchantStatusId = 0
    var videoURL = ""//"http://clips.vorwaerts-gmbh.de/VfE_html5.mp4"
    var coverURL = ""//"https://test-mm.eastasia.cloudapp.azure.com/api/resizer/view?key=16280922ab2aadca1a24348b4dfab288&w=1000&b=productimages"
    
    var couponCount = 0   // == 0 没有满减   > 0 满减
    var shippingFee = 0   // > 0 不包邮
    
    var map: Map?
    var currentSkuId = 0
    var currentImageKey:String {
        get {
            if let currentSku = currentDefaultSku() {
                if let key = findImageKeyByColorKey(currentSku.colorKey),!key.isEmpty {
                     return key
                }
            }
            return imageDefault
        }
    }
    var currentPriceRetail:Double {
        get {
            if let currentSku = currentDefaultSku() {
                return currentSku.priceRetail
            }
            return priceRetail
        }
    }
    var currentPriceSale:Double {
        get {
            if let currentSku = currentDefaultSku() {
                return  currentSku.priceSale
            }
           return priceSale
        }
    }
    var currentOnSale:Bool {
        get {
            if let currentSku = currentDefaultSku() {
                return currentSku.isOnSale()
            }
            return isOnSale()
        }
    }
    
    // Custom
    @objc dynamic var selected = true
    @objc dynamic var selectedSkuId = -1
    @objc dynamic var selectedColorId = -1
    @objc dynamic var selectedSkuColor: String?
    @objc dynamic var selectedColorKey = "" {
        didSet {
            // Auto update SelectedColorId base on selectedColorKey
            if selectedColorKey.isEmptyOrNil() {
                selectedColorId = -1
            } else {
                selectedColorId = findColorIdByColorKey(selectedColorKey)
            }
        }
    }
    @objc dynamic var selectedSizeId = -1
    @objc dynamic var colorIndexSelected = -1
    @objc dynamic var sizeIndexSelected = -1
    
    var validColorList = [Color]()
    var validSizeList = [Size]()
    
    let uniqueId = Utils.UUID()
    var index = 0
    
    var sizeGridImage: String? {
        get {
            if let category = topCategoryPriority() {
                return category.sizeGridImage
            }
            return nil
        }
    }
    
    var skuSizeComment: String?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        self.map = map
        
        styleId                     <- map["StyleId"]
        styleCode                   <- map["StyleCode"]
        merchantId                  <- map["MerchantId"]
        imageDefault                <- map["ImageDefault"]
        priceRetail                 <- map["PriceRetail"]
        priceSale                   <- map["PriceSale"]
        saleFrom                    <- (map["SaleFrom"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        saleTo                      <- (map["SaleTo"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        availableFrom               <- (map["AvailableFrom"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        availableTo                 <- (map["AvailableTo"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        brandId                     <- map["BrandId"]
        brandStatusId               <- map["BrandStatusId"]
        brandName                   <- map["BrandName"]
        brandNameInvariant          <- map["BrandNameInvariant"]
        brandHeaderLogoImage        <- map["BrandHeaderLogoImage"]
        brandSmallLogoImage         <- map["BrandSmallLogoImage"]
        skuName                     <- map["SkuName"]
        skuNameInvariant            <- map["SkuNameInvariant"]
        primaryCategoryId           <- map["PrimaryCategoryId"]
        statusId                    <- map["StatusId"]
        statusName                  <- map["StatusName"]
        statusNameInvariant         <- map["StatusNameInvariant"]
        primaryCategoryPathList     <- map["PrimaryCategoryPathList"]
        sizeList                    <- map["SizeList"]
        colorList                   <- map["ColorList"]
        featuredImageList           <- map["FeaturedImageList"]
        descriptionImageList        <- map["DescriptionImageList"]
        colorImageList              <- map["ColorImageList"]
        skuDesc                     <- map["SkuDesc"]
        skuList                     <- map["SkuList"]
        lastCreated                 <- map["LastCreated"]
        manufacturerName            <- map["ManufacturerName"]
        launchYear                  <- map["LaunchYear"]
        skuDescInvariant            <- map["SkuDescInvariant"]
        skuFeature                  <- map["SkuFeature"]
        skuFeatureInvariant         <- map["SkuFeatureInvariant"]
        seasonId                    <- map["SeasonId"]
        seasonName                  <- map["SeasonName"]
        seasonNameInvariant         <- map["SeasonNameInvariant"]
        badgeId                     <- map["BadgeId"]
        badgeName                   <- map["BadgeName"]
        badgeImage                  <- map["BadgeImage"]
        badgeNameInvariant          <- map["BadgeNameInvariant"]
        geoCountryId                <- map["GeoCountryId"]
        geoCountryName              <- map["GeoCountryName"]
        geoCountryNameInvariant     <- map["geoCountryNameInvariant"]
        primarySkuId                <- map["PrimarySkuId"]
        isNew                       <- map["IsNew"]
        isSale                      <- map["IsSale"]
        totalLocationCount          <- map["totalLocationCount"]
        categoryPriorityList        <- map["CategoryPriorityList"]
        skuSizeComment              <- map["SkuSizeComment"]
        isCrossBorder               <- map["IsCrossBorder"]
        merchantCode                <- map["MerchantCode"]
        merchantStatusId            <- map["MerchantStatusId"]
        videoURL                    <- map["VideoURL"]
        coverURL                    <- map["CoverURL"]
        
        couponCount                 <- map["CouponCount"]
        shippingFee                 <- map["ShippingFee"]
        currentSkuId                <- map["CurrentSkuId"]
        
        sizeList.sort(by: { $0.sizeId < $1.sizeId })
        validColorList = self.getValidColorList()
        validSizeList = self.getValidSizeList()
    }
    
    func searchValidSku(_ sizeId: Int?, colorId: Int?, skuColor: String?) -> Sku?{
        if let sku = searchSku(sizeId, colorId: colorId, skuColor: skuColor), sku.isValid(){
            return sku
        }
        return nil
    }
    
    @discardableResult
    func searchSku(_ sizeId: Int?, colorId: Int?, skuColor: String?) -> Sku? {
        guard let sizeId = sizeId, let colorId = colorId, let skuColor = skuColor else {
            return nil
        }
        
        // 优先返回default, default满足上面条件
        if let def = self.defaultSku(), def.isValid()
            && !def.isOutOfStock()
            && (def.sizeId == sizeId || sizeId == -1)
            && (def.skuColor == skuColor || skuColor.isEmptyOrNil())
            && (def.colorId == colorId || colorId == -1) {
            return def
        }
        
        //返回库存充足的
        var sku: Sku?
        var filteredSku = skuList.filter{ ($0.sizeId == sizeId || sizeId == -1) && ($0.skuColor == skuColor || skuColor.isEmptyOrNil()) && ($0.colorId == colorId || colorId == -1)}
        filteredSku = filteredSku.filter{$0.isValid() && !$0.isOutOfStock()}
        let sortedSkus = filteredSku.sorted(by: { $0.qty > $1.qty })
        if sortedSkus.count > 0 {
            sku = sortedSkus[0]
        }
        return sku
    }

    
    func searchSkuIdAndColorKey(_ sizeId: Int, colorKey: String) -> Sku? {
        var sku: Sku?
        var filteredSku = skuList.filter{ ($0.sizeId == sizeId || sizeId == -1) && ($0.colorKey == colorKey || colorKey.isEmptyOrNil())}
        filteredSku = filteredSku.filter{$0.isValid() && !$0.isOutOfStock()}
        let sortedSkus = filteredSku.sorted(by: { $0.qty > $1.qty })
        if sortedSkus.count > 0 {
            sku = sortedSkus[0]
        }
        return sku
    }
    
    func findColorKeyFromSkuColor(_ skuColor: String) -> String {

        let keys = colorList.filter{ $0.skuColor == skuColor }
        if keys.count > 0 {
            return keys[0].colorKey
        }
        return ""
    }
    
    func findSkuColorFromColorKey(_ colorKey: String) -> String {
        
        let keys = colorList.filter{ $0.colorKey == colorKey }
        if keys.count > 0 {
            return keys[0].skuColor
        }
        return ""
    }
    
    /* 因为colorId重复，所以此方法废弃
    func searchSkuIdAndColorKey(_ sizeId: Int, colorId: Int) -> Sku? {
        var sku: Sku?
        var filteredSku = skuList.filter{ ($0.sizeId == sizeId || sizeId == -1) && ($0.colorId == colorId || colorId == -1) }
        filteredSku = filteredSku.filter{$0.isValid() && !$0.isOutOfStock()}
        let sortedSkus = filteredSku.sorted(by: { $0.qty > $1.qty })
        if sortedSkus.count > 0 {
            sku = sortedSkus[0]
        }
        
        return sku
    }*/
    
    /* 因为colorId重复，所以此方法废弃
    @available(*, deprecated)
    func searchSku(_ sizeId: Int, colorId: Int) -> Sku? {
        var sku: Sku?
        var filteredSku = skuList.filter{ ($0.sizeId == sizeId || sizeId == -1) && ($0.colorId == colorId || colorId == -1) }
        filteredSku = filteredSku.filter{$0.isValid() && !$0.isOutOfStock()}
        let sortedSkus = filteredSku.sorted(by: { $0.qty > $1.qty })
        if sortedSkus.count > 0 {
            sku = sortedSkus[0]
        }
        
        return sku
    }*/
    
    @available(*, deprecated)
    func searchSku(_ sizeId: Int, colorKey: String?) -> Sku? {
        var sku: Sku?
        var filteredSku = skuList.filter{ ($0.sizeId == sizeId || sizeId == -1) && ($0.colorKey == colorKey || colorKey == nil) }
        filteredSku = filteredSku.filter{$0.isValid() && !$0.isOutOfStock()}
        let sortedSkus = filteredSku.sorted(by: { $0.qty > $1.qty })
        if sortedSkus.count > 0 {
            sku = sortedSkus[0]
        }
        
        return sku
    }

    func isWished() -> Bool {
        if let cartItems = CacheManager.sharedManager.wishlist?.cartItems {
            for cartItem in cartItems {
                if cartItem.styleCode == styleCode && cartItem.merchantId == merchantId{
                    return true
                }
            }
        }
        return false
    }
    
    func findSkuBySkuId(_ skuId: Int) -> Sku? {
        for sku in skuList {
            if sku.skuId == skuId {
                return sku
            }
        }
        return nil
    }
    
    func findImageKeyByColorKey(_ colorKey: String) -> String? {
        for image in colorImageList {
            if image.colorKey.lowercased() == colorKey.lowercased() {
                return image.imageKey
            }
        }
        
        if let featureImage = featuredImageList.first{
            return featureImage.imageKey
        }
        
        return colorImageList.first?.imageKey
    }
    
    func findSuitableImageKey(_ colorId: Int) ->  String? {
        var key = findColorKeyByColorId(colorId)
        if key == nil || key!.isEmpty {
            key = defaultSku()?.colorKey
        }
        
        if let key = key {
            return findImageKeyByColorKey(key)
        }
        
        return self.imageDefault
    }
    
    // 因为colorId重复，所以仅仅找第一个合适的即可
    private func findColorKeyByColorId(_ colorId: Int) -> String? {
        for color in colorList {
            if color.colorId == colorId {
                return color.colorKey
            }
        }
        
        return nil
    }
    
    // 因为colorId重复，所以此方法废弃
    // @available(*, deprecated)
    private func findColorIdByColorKey(_ colorKey: String) -> Int {
        if let color = colorList.filter({ $0.colorKey == colorKey }).first {
            return color.colorId
        }
        
        return -1
    }
    
    private func topCategoryPriority() -> Cat? {
        var topCategory: Cat?
        
        if let categoryList = categoryPriorityList {
            for category in categoryList {
                if topCategory == nil || (topCategory != nil && category.priority < topCategory!.priority) {
                    topCategory = category
                }
            }
        }
        
        return topCategory
    }
    
	func highestCategoryPriority() -> Cat? {
		var topCategory: Cat?
		
		if let categoryList = categoryPriorityList {
			for category in categoryList {
				if category.priority == 0 {
					if topCategory == nil || (topCategory?.level < category.level && category.sizeGridImage.length > 0) {
						topCategory = category
					}
				}
			}
		}
		
		return topCategory
	}

    func haveSizeGrid() -> Bool {
        var haveComment = false
        var haveSizeGrid = false
        
        if let comment = skuSizeComment {
            haveComment = comment.length > 0
        }
        
        if let highestCategoryPriority = highestCategoryPriority(), highestCategoryPriority.sizeGridImage.length > 0 {
            haveSizeGrid = true       
        }
        
        return haveSizeGrid || haveComment
    }
    
    func defaultSkuId() -> Int {
        if let sku = defaultSku() {
            return sku.skuId
        }
        
        return NSNotFound
    }
    
    func currentDefaultSku() -> Sku? {
        var _sku: Sku?
        for sku in skuList {
            if sku.skuId == currentSkuId {
                _sku = sku
                break
            }
        }
        
        if let _ = _sku{
            return _sku
        }
        
        return defaultSku()
    }
    
    func defaultSku() -> Sku? {
        
        var _sku: Sku?
        for sku in skuList {
            if sku.isDefault == 1 {
                _sku = sku
                break
            }
        }
        
        if let _ = _sku{
            return _sku
        }
        
        return nil
    }
    
    func cacheableObject(_ skuId: Int) -> StyleCacheObject {
        return StyleCacheObject(skuId: skuId, style: self)
    }
    
    func getDefaultImageList() -> [Img] {
        var defaulImageList = [Img]()
        
        if let defaultSku = defaultSku() {
            let colorList = self.colorList.filter({ $0.colorId == defaultSku.colorId && $0.colorKey == defaultSku.colorKey})
            
            if !colorList.isEmpty {
                let colorKey = colorList[0].colorKey
                defaulImageList = colorImageList.filter({ $0.colorKey == colorKey })
                defaulImageList = defaulImageList.sorted(by: { $0.position < $1.position })
            }
        }
        
        return defaulImageList
    }
    
    func isEmptyColorList() -> Bool {
        if colorList.isEmpty {
            return true
        }
        
        if colorList.count == 1 {
            // This logic define by API colorId = 1 is No Color
            if colorList[0].colorId == 1 {
                return true
            }
        }
        
        return false
    }
    
    func isEmptySizeList() -> Bool {
        if sizeList.isEmpty {
            return true
        }
        
        if sizeList.count == 1 {
            // This logic define by API sizeId = 1 is No Size
            if sizeList[0].sizeId == 1 {
                return true
            }
        }
        
        if sizeList.count == 0 {
            return true
        }
        
        return false
    }
    
    func isAvailable() -> Bool {
        return DateHelper.currentTimeInRange(dateFrom: availableFrom, dateTo: availableTo)
    }
    
    func isOutOfStock() -> Bool {
        for sku in skuList {
            if !sku.isOutOfStock() && sku.isValid() {
                return false
            }
        }
        
        return true
    }
    
    func isValid() -> Bool {
        return !isInvalid()
    }
    
    // Avoid using isInvalid directly
    private func isInvalid() -> Bool {
        var isInvalid = true
        
        if merchantStatusId != Constants.StatusID.active.rawValue {
            isInvalid = true
        }
        
        if brandStatusId != Constants.StatusID.active.rawValue {
            isInvalid = true
        }
        
        // All categories inactive mean product must be inactive
        if let categoryPriorityList = categoryPriorityList {
            var isAllCategoryInactive = true
            for currentCategoryPriority in categoryPriorityList {
                if currentCategoryPriority.statusId != Constants.StatusID.inactive.rawValue {
                    isAllCategoryInactive = false
                    break
                }
            }
            
            if isAllCategoryInactive {
                isInvalid = true
            }
        }
        
        for sku in skuList {
            if sku.isValid() {
                isInvalid = false
            }
        }
        
        return isInvalid || !isAvailable()
    }
    
    func getColorAtIndex(_ index: Int) -> Color? {
        if index >= 0 && index < colorList.count {
            let color: Color = colorList[index]
            return color
        }
        
        return nil
    }
    
    func getValidColorAtIndex(_ index: Int) -> Color? {
        if index >= 0 && index < validColorList.count {
            let color: Color = validColorList[index]
            return color
        }
        
        return nil
    }
    
    @available(*, deprecated)
    func getColorKeyAtIndex(_ index: Int) -> String {
        if index >= 0 && index < colorList.count {
            let color: Color = colorList[index]
            return color.colorKey
        }
        
        if colorList.count == 1 && colorList[0].colorId == 1 {
            // NoColor case
            return colorList[0].colorKey
        }
        
        return ""
    }
    
    func getSizeIdAtIndex(_ index: Int) -> Int {
        if index >= 0 && index < sizeList.count {
           let size: Size = sizeList[index]
           return size.sizeId
           
        }
        
        if sizeList.count == 1 && sizeList[0].sizeId == 1 {
            // NoSize case
            return sizeList[0].sizeId
        }
        
        return -1
    }
    
    func getValidSizeIdAtIndex(_ index: Int) -> Int {
        if index >= 0 && index < validSizeList.count {
            let size: Size = validSizeList[index]
            return size.sizeId
            
        }
        
        if validSizeList.count == 1 && validSizeList[0].sizeId == 1 {
            // NoSize case
            return validSizeList[0].sizeId
        }
        
        return -1
    }
    
    func getColorIndexFor(_ colorKey: String) -> Int {
        for index in 0..<colorList.count {
            if colorList[index].colorKey == colorKey {
                return index
            }
        }
        return -1
    }
    
    //MM-19474 Get SKU price by selected index of style and selected index of size
    func getSkuPrice(colorIndex: Int, sizeIndex: Int) -> Double {
        var price: Double = 0
        var skuSelected: Sku? = nil
        let sizeIdSelected = getSizeIdAtIndex(sizeIndex)
        
        if colorIndex == -1 && sizeIndex == -1 {
            skuSelected = defaultSku()
        } else if let colorSelected = getValidColorAtIndex(colorIndex), let searchSku = searchSku(sizeIdSelected, colorId: colorSelected.colorId, skuColor: colorSelected.skuColor) {
            skuSelected = searchSku
        } else {
            skuSelected = defaultSku()
        }
        
        if skuSelected != nil {
            price = skuSelected!.price()
        } else {
            //In case of can't get sku we display style price
            price = (isOnSale()) ? priceSale : priceRetail
        }
        
        return price
    }

    
    func getSkuPrice(colorKey: String, sizeId: Int) -> Double {
        var skuSelected: Sku? = nil
        
        if let searchSku = searchSkuIdAndColorKey(sizeId, colorKey: colorKey) {
            skuSelected = searchSku
        } else {
            skuSelected = defaultSku()
        }
        
        var price: Double = 0
        
        if skuSelected != nil {
            price = skuSelected!.price()
        } else {
            //In case of can't get sku we display style price
            if isOnSale() {
                price = priceSale
            } else {
                price = priceRetail
            }
        }
        
        return price
    }
    
    func getValidSkusBySizeId(_ sizeId: Int) -> [Sku]{
        var skus = skuList.filter({ $0.sizeId == sizeId })
        skus = skus.filter({ !$0.isOutOfStock() && $0.isValid()})
        return skus
    }
    
    func getValidSkusByColorId(_ colorId: Int) -> [Sku]{
        var skus = skuList.filter({ $0.colorId == colorId })
        skus = skus.filter({ !$0.isOutOfStock() && $0.isValid()})
        return skus
    }
    
    func getValidSkusByColorKey(_ colorKey: String) -> [Sku]{
        var skus = skuList.filter({ $0.colorKey == colorKey })
        skus = skus.filter({ !$0.isOutOfStock() && $0.isValid()})
        return skus
    }
    
    func getValidSkuList() -> [Sku]{
        var skus = skuList
        skus = skus.filter({ !$0.isOutOfStock() && $0.isValid()})
        return skus
    }
    
    func getValidColorList() -> [Color]{
        return self.colorList.filter({ (color) -> Bool in
            return self.skuList.contains(where: { (sku) -> Bool in
                if sku.colorId == color.colorId && sku.skuColor == color.skuColor{
                    return !sku.isOutOfStock() && sku.isValid()
                }
                return false
            })
        })
    }
    
    func getValidSizeList() -> [Size]{
        return self.sizeList.filter({ (size) -> Bool in
            return self.skuList.contains(where: { (sku) -> Bool in
                if sku.sizeId == size.sizeId{
                    return !sku.isOutOfStock() && sku.isValid()
                }
                return false
            })
        })
    }
    
    func getRangePrice() -> String {
        var priceString = ""
        let validSkuList = getValidSkuList()
        if validSkuList.count > 0 {
            var lowestPrice: Double = validSkuList[0].isOnSale() ? validSkuList[0].priceSale : validSkuList[0].priceRetail
            var highestPrice: Double = validSkuList[0].isOnSale() ? validSkuList[0].priceSale : validSkuList[0].priceRetail
            for sku in validSkuList{
                var skuPrice: Double = 0
                if (sku.isOnSale()){
                    skuPrice = sku.priceSale
                }else{
                    skuPrice = sku.priceRetail
                }
                if skuPrice < lowestPrice {
                    lowestPrice = skuPrice
                }
                if skuPrice > highestPrice {
                    highestPrice = skuPrice
                }
            }
            // Result
            if (lowestPrice == highestPrice) {
                priceString = highestPrice.formatPrice()!
            }else{
                priceString = lowestPrice.formatPrice()! + " ~ " + highestPrice.formatPrice()!
            }
            
            if (lowestPrice == 0 && highestPrice == 0){
                priceString = ""
            }

        }
        
        return priceString
    }
    
    func copy() -> Style {
        let style = Style()
        
        if let map = map {
            style.mapping(map: map)
        }
        
        return style
    }
    
    func containFlashSale() -> Bool {
        for sku in self.skuList {
            if sku.isFlashSaleExists && DateHelper.currentTimeInRange(dateFrom: sku.flashSaleFrom, dateTo: sku.flashSaleTo) {
                return true
            }
        }
        return false
    }
    
    func getFlashSaleSku() -> Sku? {
        //优先返回default
        if let defaultSku = self.defaultSku(), defaultSku.isFlashSaleExists
            && DateHelper.currentTimeInRange(dateFrom: defaultSku.flashSaleFrom, dateTo: defaultSku.flashSaleTo)
            && defaultSku.isValid()
            && !defaultSku.isOutOfStock() {
            return defaultSku
        }
        for sku in self.skuList {
            if sku.isFlashSaleExists
                && DateHelper.currentTimeInRange(dateFrom: sku.flashSaleFrom, dateTo: sku.flashSaleTo)
                && sku.isValid()
                && !sku.isOutOfStock()  {
                return sku
            }
        }
        return nil
    }
    
    func minFlashSale() -> Double {
        var price = self.priceRetail
        for sku in self.skuList {
            if sku.isFlashSaleExists && DateHelper.currentTimeInRange(dateFrom: sku.flashSaleFrom, dateTo: sku.flashSaleTo) {
                if sku.priceFlashSale < price {
                    price = sku.priceFlashSale
                }
            }
        }
        return price
    }
    
    func isOnSale() -> Bool {
        var _isSale = false
        _isSale = DateHelper.currentTimeInRange(dateFrom: saleFrom, dateTo: saleTo)
        if (priceSale == 0) {
            _isSale = false
        }
        return _isSale
    }
}
