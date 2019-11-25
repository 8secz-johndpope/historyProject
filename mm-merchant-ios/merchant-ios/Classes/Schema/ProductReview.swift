//
//  ProductReview.swift
//  merchant-ios
//
//  Created by Gam Bogo on 6/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class ProductReview : Mappable {
    var reviewCount = 0
    var ratingAverage: Float = 0
    var skuReview: SkuReview?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        reviewCount                 <- map["ReviewCount"]
        ratingAverage               <- map["RatingAverage"]
        skuReview                   <- map["SkuReview"]
    }
    
}
