//
//  Sku.swift
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

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
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

class Sku : Mappable, Equatable, CustomStringConvertible {
 
    static func ==(lhs: Sku, rhs: Sku) -> Bool {
        return lhs.skuId == rhs.skuId
    }
    
    var skuId = 0
    var styleId = 0
    var cartItemId = 0
    var qty = 0
    var videoURL = ""
    var styleCode = ""
    var skuCode = ""
    var bar = ""
    var brandId = 0
    var brandName = ""
    var brandNameInvariant = ""
    var brandImage = ""
    var badgeId = 0
    var seasonId = 0
    var sizeId = 0
    
//    @available(*, deprecated)
    var colorId = 0 //colorId定义设计问题，并不是id，仅仅标识色系，会重复
    
    var geoCountryId = 0
    var launchYear = 0
    var priceRetail: Double = 0
    var priceSale: Double = 0
    var saleFrom: Date?
    var saleTo: Date?
    var availableFrom: Date?
    var availableTo: Date?
    var lastCreated = ""
    var qtySafetyThreshold = 0
    var merchantId = 0
    var statusId = 0
    var primaryCategoryId = 0
    var sizeName = ""
    var colorKey = ""
    var colorCode = ""
    var colorImage = ""
    var colorName = ""
    var skuColor = ""
    var skuName = ""
    var locationCount = 0
    var qtyAts: Any?
    var inventoryStatusId = 0
    var isNew = 0
    var isSale = 0
    var isDefault = 0
    var positionX = 0
    var positionY  = 0
    var place = TagPlace.undefined
    var imageDefault = ""
    var productImage = ""
    var productTag:Int = 0
    var isCrossBorder = 0
    var couponCount = 0
    var shippingFee = 0
    var flashSaleFrom: Date?
    var flashSaleTo: Date?
    var isFlashSaleExists = false
    var priceFlashSale: Double = 0
    
    var description: String {
        get {
            return "id: \(skuId), PriceSale : \(priceSale), PriceRetail : \(priceRetail)"
        }
    }
	
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        skuId                           <- map["SkuId"]
        styleId                         <- map["StyleId"]
        cartItemId                      <- map["CartItemId"]
        qty                             <- map["Qty"]
        videoURL                        <- map["VideoURL"]
        styleCode                       <- map["StyleCode"]
        skuCode                         <- map["SkuCode"]
        bar                             <- map["Bar"]
        brandId                         <- map["BrandId"]
        brandName                       <- map["BrandName"]
        brandNameInvariant              <- map["BrandNameInvariant"]
        brandImage                      <- map["BrandHeaderLogoImage"] // from cart item
        brandImage                      <- map["BrandImage"]
        badgeId                         <- map["BadgeId"]
        seasonId                        <- map["SeasonId"]
        sizeId                          <- map["SizeId"]
        colorId                         <- map["ColorId"]
        geoCountryId                    <- map["GeoCountryId"]
        launchYear                      <- map["LaunchYear"]
        priceRetail                     <- map["PriceRetail"]
        priceSale                       <- map["PriceSale"]
        saleFrom                        <- (map["SaleFrom"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        saleTo                          <- (map["SaleTo"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        availableFrom                   <- (map["AvailableFrom"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        availableTo                     <- (map["AvailableTo"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        qtySafetyThreshold              <- map["QtySafetyThreshold"]
        merchantId                      <- map["MerchantId"]
        statusId                        <- map["StatusId"]
        primaryCategoryId               <- map["PrimaryCategoryId"]
        sizeName                        <- map["SizeName"]
        colorKey                        <- map["ColorKey"]
        colorName                       <- map["ColorName"]
        skuColor                        <- map["SkuColor"]
        skuName                         <- map["SkuName"]
        locationCount                   <- map["LocationCount"]
        qtyAts                          <- map["QtyAts"]
        inventoryStatusId               <- map["InventoryStatusId"]
        lastCreated                     <- map["LastCreated"]
        colorCode                       <- map["ColorCode"]
        colorImage                      <- map["ColorImage"]
        isNew                           <- map["IsNew"]
        isSale                          <- map["IsSale"]
        isDefault                       <- map["IsDefault"]
        positionX                       <- map["PositionX"]
        positionY                       <- map["PositionY"]
        place                           <- map["Place"]
        productImage                    <- map["ImageDefault"]  //from cart item
        productImage                    <- map["ProductImage"]
        isCrossBorder                   <- map["IsCrossBorder"]
        couponCount                     <- map["CouponCount"]
        shippingFee                     <- map["ShippingFee"]
        flashSaleFrom                   <- (map["FlashSaleFrom"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        flashSaleTo                     <- (map["FlashSaleTo"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        isFlashSaleExists               <- map["IsFlashSaleExists"]
        priceFlashSale                  <- map["PriceFlashSale"]
    }
    
    func price(_ isFlashSale:Bool = false) -> Double {
        if isFlashSale && priceFlashSale > 0 && isFlashOnSale() {
            return priceFlashSale
        } else if priceSale != 0 && isOnSale() {
            return priceSale
        } else {
            return priceRetail
        }
    }

    func isWished() -> Bool {
        if let cartItems = CacheManager.sharedManager.wishlist?.cartItems {
            for cartItem in cartItems {
                if cartItem.skuId == self.skuId {
                    return true
                }
            }
        }
        return false
    }
    
    func isAvailable() -> Bool {
        if (availableFrom == nil) && (availableTo == nil){
            return true
        }
        return DateHelper.currentTimeInRange(dateFrom: availableFrom, dateTo: availableTo)
    }
    
    func isValid() -> Bool {
        //Only 1 case Active is product valid otherwise is invalid (Delete, Pending, Inactive)
        return statusId == Constants.StatusID.active.rawValue && isAvailable()
    }
    
    func isOutOfStock() -> Bool {
        if let inventoryStatusId = Constants.InventoryStatusID(rawValue: self.inventoryStatusId){
            switch inventoryStatusId {
            case .outOfStock, .notAvailable:
                return true
            default:
                break
            }
        }
        
        if qtyAts == nil {
            return true
        }
        
        if let qtyAts = qtyAts as? String {
            if qtyAts.isEmptyOrNil() || (qtyAts != "Unlimited" && Int(qtyAts) <= 0) {
                return true
            }
        } else if let qtyAts = qtyAts as? Int {
            if qtyAts <= 0 {
                return true
            }
        }
        
        return false
    }
    
    func isExceededQtyAts(withQty qty: Int) -> Bool {
        if qtyAts == nil {
            return true
        }
        
        if let qtyAts = qtyAts as? String {
            if qtyAts.isEmptyOrNil() {
                return true
            } else if qtyAts == "Unlimited" {
                return false
            } else {
                return qty > Int(qtyAts)
            }
        } else if let qtyAts = qtyAts as? Int {
            return qty > qtyAts
        }
        
        return true
    }
    
    func createStyle() -> Style{
        let style = Style()
        style.styleCode = self.styleCode
        style.merchantId = self.merchantId
        style.brandName = self.brandName
        style.brandSmallLogoImage = self.brandImage
        style.brandId = self.brandId
        style.skuName = self.skuName
        style.primarySkuId = self.skuId
        style.imageDefault = self.productImage
        style.selectedColorKey = self.colorKey
        style.selectedSkuId = self.skuId
        style.selectedSizeId = self.sizeId
        style.selectedColorId = self.colorId
        style.skuList = [self]
        
        return style
    }
    
    func isOnSale() -> Bool {
        var _isSale = false
        _isSale = DateHelper.currentTimeInRange(dateFrom: saleFrom, dateTo: saleTo)
        if (priceSale == 0) {
            _isSale = false
        }
        return _isSale
    }
    
    func isFlashOnSale() -> Bool {
        var _isSale = false
        _isSale = DateHelper.currentTimeInRange(dateFrom: flashSaleFrom, dateTo: flashSaleTo)
        if (priceFlashSale == 0) {
            _isSale = false
        }
        return _isSale
    }
}
