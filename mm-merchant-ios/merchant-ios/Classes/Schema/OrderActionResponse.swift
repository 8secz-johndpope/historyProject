//
//  OrderActionResponse.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderActionResponse: Mappable {
    
    var entityId = ""
    var message = ""
    var success = false
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        entityId    <- map["EntityId"]
        message     <- map["Message"]
        success     <- map["Success"]
        
    }
    
}
