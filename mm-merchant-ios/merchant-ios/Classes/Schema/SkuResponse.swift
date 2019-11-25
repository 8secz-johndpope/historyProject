//
//  SkuResponse.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 27/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
class SkuResponse : Mappable{
    var sizeId = 0
    var sizeCode = ""
    var sizeName = ""
    var sizeGroup = ""
    
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        sizeId                  <- map["SizeId"]
        sizeCode                <- map["SizeCode"]
        sizeName                <- map["SizeName"]
        sizeGroup               <- map["SizeGroup"]
    }
    
}
