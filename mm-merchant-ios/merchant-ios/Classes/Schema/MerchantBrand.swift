//
//  MerchantBrand.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/28/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class MerchantBrand : Mappable {
    
    var merchantId = 0
    var statusId = 0
    var brandList: [Int] = []
    var elasticUpdateKey = ""
    var elasticUpdateLast = ""
    var elasticScore = ""
    var isCrossBorder = 0
    var couponCount = 0
    var isNew = 0
    var newStyleCount = 0
    var newSaleCount = 0

    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        merchantId          <- map["MerchantId"]
        statusId            <- map["StatusId"]
        brandList           <- map["BrandList"]
        elasticUpdateKey    <- map["ElasticUpdateKey"]
        elasticUpdateLast   <- map["ElasticUpdateLast"]
        elasticScore        <- map["ElasticScore"]
        isCrossBorder       <- map["IsCrossBorder"]
        couponCount         <- map["CouponCount"]
        isNew               <- map["IsNew"]
        newStyleCount       <- map["NewStyleCount"]
        newSaleCount        <- map["NewSaleCount"]
    }
    
}
