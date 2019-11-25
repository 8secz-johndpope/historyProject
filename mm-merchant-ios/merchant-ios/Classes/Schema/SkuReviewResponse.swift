//
//  SkuReviewResponse.swift
//  merchant-ios
//
//  Created by Gam Bogo on 6/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class SkuReviewResponse: Mappable {
    
    var hitsTotal = 0
    var pageCurrent = 0
    var pageData: [SkuReview]?
    var pageSize = 0
    var pageTotal = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        hitsTotal               <- map["HitsTotal"]
        pageCurrent             <- map["PageCurrent"]
        pageData                <- map["PageData"]
        pageSize                <- map["PageSize"]
        pageTotal               <- map["PageTotal"]
        
    }
    
}
