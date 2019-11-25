//
//  AfterSalesHistory.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 17/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class AfterSalesHistory: Mappable {
    
    var order: Order?
    var orderHistory: [OrderHistory]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        order                        <- map["Order"]
        orderHistory                 <- map["OrderHistory"]
        
    }
}
