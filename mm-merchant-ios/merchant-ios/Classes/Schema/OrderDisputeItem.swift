//
//  OrderDisputeItem.swift
//  merchant-ios
//
//  Created by Gambogo on 20/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderDisputeItem: Mappable {
    
    var lastCreated = Date()
    var lastModified = Date()
    var qtyDisputed = 0
    var skuId = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        lastCreated                     <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                    <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        qtyDisputed                     <- map["QtyReturned"]//TODO: should roll back to map["QtyDisputed"]
        skuId                           <- map["SkuId"]
        
    }
}
