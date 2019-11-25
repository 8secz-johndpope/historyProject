//
//  CouponList.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 9/25/17.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class HashTagList: Mappable {
    var hitsTotal = 0
    var pageTotal = 0
    var pageSize = 0
    var pageCurrent = 0
    var pageData: [HashTag]?
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        hitsTotal               <- map["HitsTotal"]
        pageTotal               <- map["PageTotal"]
        pageSize                <- map["PageSize"]
        pageCurrent             <- map["PageCurrent"]
        pageData                <- map["PageData"]
    }
        
    
}
