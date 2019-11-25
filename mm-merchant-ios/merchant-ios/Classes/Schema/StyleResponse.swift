//
//  StyleResponse.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 27/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
class StyleResponse : Mappable{
    var rowTotal = 0
    var pageCount = 0
    var pageSize = 0
    var pageCurrent = 0
    var data : [Style]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        rowTotal                <- map["RowTotal"]
        pageCount               <- map["PageCount"]
        pageSize                <- map["PageSize"]
        pageCurrent             <- map["PageCurrent"]
        data                    <- map["Data"]
    }
    
}
