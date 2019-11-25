//
//  OrderCancelReason.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 19/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderCancelReason: BaseReason {
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        reasonId                    <- map["OrderCancelReasonId"]
        reasonName                  <- map["OrderCancelReasonName"]
        reasonNameInvariant         <- map["OrderCancelReasonNameInvariant"]
        
    }
}
