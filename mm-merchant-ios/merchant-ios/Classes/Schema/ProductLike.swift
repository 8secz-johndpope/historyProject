//
//  Product.swift
//  merchant-ios
//
//  Created by Gambogo on 22/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import RealmSwift
import ObjectMapper

class ProductLike: Mappable {
    
    var styleId = 0
    var styleCode = ""
    var merchantId = 0
    var likeCount = 0
    var likeList : [ProductLikeItem] = []
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        styleId                 <- map["StyleId"]
        styleCode               <- map["StyleCode"]
        merchantId              <- map["MerchantId"]
        likeCount               <- map["LikeCount"]
        likeList                <- map["LikeList"]
    }
}
