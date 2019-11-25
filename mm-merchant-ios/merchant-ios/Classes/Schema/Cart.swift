//
//  Cart.swift
//  merchant-ios
//
//  Created by HungPM on 1/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Cart : Mappable{
    var cartKey = ""
    var wishlistKey = ""
    var cartTypeId = 0
    var statusId = 0
    var userKey = ""
    var merchantList : [CartMerchant]?
    var lastCreated = ""
    var lastModified = ""
    var itemList : [CartItem]?

    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        cartKey               <- map["CartKey"]
        wishlistKey           <- map["WishlistKey"]
        cartTypeId            <- map["CartTypeId"]
        statusId              <- map["StatusId"]
//        merchantList          <- map["MerchantList"]
        userKey               <- map["UserKey"]
        lastCreated           <- map["LastCreated"]
        lastModified          <- map["LastModified"]
        itemList              <- map["ItemList"]
    }
}
