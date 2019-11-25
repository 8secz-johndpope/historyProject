//
//  Syte.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/20.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Syte: Mappable {
    
    var hitsTotal = 0
    var pageTotal = 0
    var pageSize = 0
    var pageCurrent = 0
    var pageData: [Style]?
    var containedSyte:Bool = false
    
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

