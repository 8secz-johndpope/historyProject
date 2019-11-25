//
//  OrderHistory.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 16/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderHistory: Mappable {
    
    var copy = ""
    var displayName = ""
    var entityId = ""
    var entityTypeId = 0
    var entityTypeName = ""
    var firstName = ""
    var lastCreated = Date()
    var lastName = ""
    var orderHistoryTypeCode = ""
    var orderHistoryTypeId = 0
    var userKey = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        copy                        <- map["Copy"]
        displayName                 <- map["DisplayName"]
        entityId                    <- map["EntityId"]
        entityTypeId                <- map["EntityTypeId"]
        entityTypeName              <- map["EntityTypeName"]
        firstName                   <- map["FirstName"]
        lastCreated                 <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastName                    <- map["LastName"]
        orderHistoryTypeCode        <- map["OrderHistoryTypeCode"]
        orderHistoryTypeId          <- map["OrderHistoryTypeId"]
        userKey                     <- map["UserKey"]
        
    }
}
