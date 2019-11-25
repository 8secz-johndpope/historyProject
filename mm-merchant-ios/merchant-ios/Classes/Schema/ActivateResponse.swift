//
//  ActivateResponse.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 15/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class ActivateResponse: Mappable {
    var success = false
    var message = ""
    var entityId = ""

    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        success     <- map["Success"]
        message     <- map["Message"]
        entityId    <- map["EntityId"]

    }
    
}
