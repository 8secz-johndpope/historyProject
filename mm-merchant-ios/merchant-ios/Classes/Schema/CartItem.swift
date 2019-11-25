//
//  CartItem.swift
//  merchant-ios
//
//  Created by Alan YU on 10/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
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


class CartItem: NSObject, Mappable {
    
    var skuId = 0
    var cartItemId = 0
    var qty = 0
    var _userKeyReferrer: String?
    var userKeyReferrer: String? {
        get {
            if let referrer = _userKeyReferrer, referrer == "0" {
                return nil
            }
            return _userKeyReferrer
        }
    }
    var styleCode = ""
    var skuCode = ""
    var bar = ""
    var brandId = 0
    var brandName = ""
    var brandNameInvariant = ""
    var brandImage = ""
    var brandCode = ""
    var badgeId = 0
    var brandStatusId = 0
    var seasonId = 0
    var sizeId = 0
    var colorId = 0
    var geoCountryId = 0
    var launchYear = 0
    var priceRetail : Double = 0
    var priceSale : Double = 0
    var saleFrom: Date?
    var saleTo: Date?
    var availableFrom: Date?
    var availableTo: Date?
    var qtySafetyThreshold = 0
    var merchantId = 0
    var merchantCode = ""
    var merchantStatusId = 0
    var statusId = 0
    var primaryCategoryId = 0
    var sizeName = ""
    var colorKey = ""
    var colorName = ""
    var skuColor = ""
    var skuName = ""
    var locationCount = 0
    var qtyAts: Any?
    var inventoryStatusId = 0
    var productImage = ""
    var lastCreated = ""
    var lastModified = ""
    
    var uniqueId = Utils.UUID()
    var index = 0
    
    @available(*, deprecated: 1.0, message: "Removed From API so it always return nil") var style : Style?
    
    var isSale = 0
    
    // custom
    @objc dynamic var selected = false
    var customStyle : Style?
    
    var styleIsOutOfStock = false
    var styleIsValid = true
    var isSelected = false
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        skuId                           <- map["SkuId"]
        cartItemId                      <- map["CartItemId"]
        qty                             <- map["Qty"]
        _userKeyReferrer                <- map["UserKeyReferrer"]
        styleCode                       <- map["StyleCode"]
        skuCode                         <- map["SkuCode"]
        bar                             <- map["Bar"]
        brandId                         <- map["BrandId"]
        brandName                       <- map["BrandName"]
        brandNameInvariant              <- map["BrandNameInvariant"]
        brandStatusId                   <- map["BrandStatusId"]
        brandImage                      <- map["BrandImage"]
        brandCode                       <- map["BrandCode"]
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
        productImage                    <- map["ProductImage"]
        lastCreated                     <- map["LastCreated"]
        lastModified                    <- map["LastModified"]
        isSale                          <- map["IsSale"]
        merchantCode                    <- map["MerchantCode"]
        merchantStatusId                <- map["MerchantStatusId"]
    }

    func price() -> Double {
        if priceSale != 0 && isSale > 0 {
            return priceSale
        } else {
            return priceRetail
        }
    }
    
    func isAvailable() -> Bool {
        return DateHelper.currentTimeInRange(dateFrom: availableFrom, dateTo: availableTo)
    }
    
    func isProductValid() -> Bool {
        //Only 1 case Active is product valid otherwise is invalid (Delete, Pending, Inactive)
        if statusId != Constants.StatusID.active.rawValue {
            return false
        }
        
        if brandStatusId != Constants.StatusID.active.rawValue {
            return false
        }
        
        if merchantStatusId != Constants.StatusID.active.rawValue {
            return false
        }
        
        return isAvailable()
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
            if qtyAts == 0 {
                return true
            }
        }
        
        return false
    }
    
    func isExceededQtyAts(qty: Int) -> Bool {
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
    
    func isOnSale() -> Bool {
        var _isSale = false
        _isSale = DateHelper.currentTimeInRange(dateFrom: saleFrom, dateTo: saleTo)
        if (priceSale == 0) {
            _isSale = false
        }
        return _isSale
    }
}
