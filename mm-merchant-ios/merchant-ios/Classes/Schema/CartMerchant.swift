//
//  CartMerchant.swift
//  merchant-ios
//
//  Created by HungPM on 1/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class CartMerchant : Mappable, Equatable {
    
    static func ==(lhs: CartMerchant, rhs: CartMerchant) -> Bool {
        return lhs.merchantId == rhs.merchantId
    }

    var merchantId = 0
    var merchantName = ""
    var merchantNameInvariant = ""
    var merchantImage = ""
    var lastModified = ""
    var freeShippingThreshold = 0
    var itemList : [CartItem]?
    var isCrossBorder = false
    var coupon: Coupon?
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        merchantId                  <- map["MerchantId"]
        merchantName                <- map["MerchantName"]
        merchantNameInvariant       <- map["MerchantNameInvariant"]
        merchantImage               <- map["MerchantImage"]
        itemList                    <- map["ItemList"]
        lastModified                <- map["LastModified"]
    }
    
    func isFreeShippingEnabled() -> Bool {
        return freeShippingThreshold < Constants.MaxFreeShippingThreshold
    }
}
