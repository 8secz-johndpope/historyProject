//
//  ShipmentItem.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class ShipmentItem: Mappable {
    
    var lastCreated = Date()
    var lastModified = Date()
    var qtyShipped = 0
    var skuId = 0
    
    // For Unprocessed shipment
    var qtyCancelled = 0
    var qtyToShip = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        lastCreated     <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified    <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        qtyShipped      <- map["QtyShipped"]
        skuId           <- map["SkuId"]
        
    }
}
