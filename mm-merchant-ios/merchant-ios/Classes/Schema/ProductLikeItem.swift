//
//  Product.swift
//  merchant-ios
//
//  Created by Gambogo on 22/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import RealmSwift
import ObjectMapper

class ProductLikeItem: Mappable {
    
    var styleId = 0
    var cartId =  0
    var cartItemId = 0
    var skuId = 0
    var styleCode = ""
    var merchantId = 0
    var userKey = ""
    var isCurator = 0
    @objc dynamic var userName = ""
    var displayName = ""
    var profileImage = ""
    var lastModified = Date()
    var elasticUpdateKey = ""
    var elasticUpdateLast = Date()
    var isLoading = false
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
         styleId            <- map["StyleId"]
         cartId             <- map["CartId"]
         cartItemId         <- map["CartItemId"]
         skuId              <- map["SkuId"]
         styleCode          <- map["StyleCode"]
         merchantId         <- map["MerchantId"]
         userKey            <- map["UserKey"]
         isCurator          <- map["IsCurator"]
         userName           <- map["UserName"]
         displayName        <- map["DisplayName"]
         profileImage       <- map["ProfileImage"]
         lastModified       <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
         elasticUpdateKey   <- map["ElasticUpdateKey"]
         elasticUpdateLast  <- (map["ElasticUpdateLast"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        
    }
    
}
