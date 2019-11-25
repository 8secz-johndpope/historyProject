//
//  OrderReturnHistory.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 23/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderReturnHistory: Mappable {
    
    var comments = ""
    var description = ""
    var displayName = ""
    var firstName = ""
    var image1 = ""
    var image2 = ""
    var image3 = ""
    var lastCreated = Date()
    var lastModified = Date()
    var orderDisputeReasonId = 0
    var orderReturnConditionId = 0
    var orderReturnHistoryKey = ""
    var orderReturnId = 0
    var orderReturnReasonId = 0
    var orderReturnStatusCode = ""
    var orderReturnStatusId = 0
    //var userId = 0
    var orderReturnStatus: OrderReturn.OrderReturnStatus = .unknown
    var userKey = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        comments                        <- map["Comments"]
        displayName                     <- map["DisplayName"]
        firstName                       <- map["FirstName"]
        description                     <- map["Description"]
        image1                          <- map["Image1"]
        image2                          <- map["Image2"]
        image3                          <- map["Image3"]
        lastCreated                     <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                    <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        orderReturnConditionId          <- map["OrderReturnConditionId"]
        orderReturnHistoryKey           <- map["OrderReturnHistoryKey"]
        orderReturnId                   <- map["OrderReturnId"]
        orderReturnReasonId             <- map["OrderReturnReasonId"]
        orderReturnStatusId             <- map["OrderReturnStatusId"]
        orderReturnStatusCode           <- map["OrderReturnStatusCode"]
        orderDisputeReasonId            <- map["OrderDisputeReasonId"]
        //userId                          <- map["userId"]
        
        orderReturnStatus               <- (map["OrderReturnStatusId"], EnumTransform<OrderReturn.OrderReturnStatus>())
        userKey                         <- map["UserKey"]
    }
    
    func getImages() ->  [String] {
        let images = [self.image1 , self.image2 , self.image3 ]
        var validImages = [String]()
        
        for image in images {
            if !image.isEmpty {
                validImages.append(image)
            }
        }
        
        return validImages
    }
}
