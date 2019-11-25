//
//  OrderReturnReason.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 19/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderReturnReason: BaseReason {
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        reasonId                    <- map["OrderReturnReasonId"]
        reasonName                  <- map["OrderReturnReasonName"]
        reasonNameInvariant         <- map["OrderReturnReasonNameInvariant"]
        
    }
}
