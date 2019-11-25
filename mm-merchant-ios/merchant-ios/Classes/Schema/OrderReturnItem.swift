//
//  OrderReturnItem.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 20/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderReturnItem: Mappable {
    
    var lastCreated: Date?
    var lastModified: Date?
    var qtyReturned = 0
    var skuCode = ""
    var skuId = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        lastCreated                     <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                    <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        qtyReturned                     <- map["QtyReturned"]
        skuCode                         <- map["SkuCode"]
        skuId                           <- map["SkuId"]
        
    }
}
