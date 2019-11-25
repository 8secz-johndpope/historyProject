//
//  SearchResponse.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 10/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class SearchResponse : Mappable{
    var hitsTotal = 0
    var hits = 0
    var pageCount = 0
    var pageSize = 0
    var pageCurrent = 0
    var pageData : [Style]?
    var pageTotal = 0
    var aggregations : Aggregations?
    var mapping: Mapping?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        hitsTotal               <- map["HitsTotal"]
        hits                    <- map["Hits"]
        pageCount               <- map["PageCount"]
        pageSize                <- map["PageSize"]
        pageCurrent             <- map["PageCurrent"]
        pageData                <- map["PageData"]
        pageTotal               <- map["PageTotal"]
        aggregations            <- map["Aggregations"]
        mapping                 <- map["Mapper"]
    }

}
