//
//  OrderDisputeReason.swift
//  merchant-ios
//
//  Created by Gambogo on 19/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderDisputeReason: BaseReason {
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        reasonId                    <- map["OrderDisputeReasonId"]
        reasonName                  <- map["OrderDisputeReasonName"]
        reasonNameInvariant         <- map["OrderDisputeReasonNameInvariant"]
        
    }
    
}
