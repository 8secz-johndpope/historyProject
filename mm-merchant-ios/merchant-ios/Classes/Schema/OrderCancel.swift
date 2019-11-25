//
//  OrderCancel.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 22/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderCancel: Mappable {
    
    enum OrderCancelStatus: Int {
        case unknown = 0
        case cancelAccepted = 2
        case cancelRequested
        case cancelRejected
    }
    
    var amount: Int?
    var comments = ""
    var couponAdjustmentAmount = 0
    var description = ""
    var displayName = ""
    var firstName = ""
    var isFreeShippingOverride = false
    var isMm = 0
    var isRefundRequested = 0
    var itemAmount = 0
    var lastCreated: Date?
    var lastModified: Date?
    var mmCouponAdjustmentAmount = 0
    var orderCancelItems: [OrderCancelItem]?
    var orderCancelKey = ""
    var orderCancelReasonId = 0
    var orderCancelStatusCode = 0
    var orderCancelStatusId = 0
    var orderCancelStatus = OrderCancelStatus.unknown
    var orderDiscountAdjustmentAmount = 0
    var orderTransactionKey = ""
    var shippingAdjustmentAmount = 0
    var userKey = ""
    var userName = ""
    var order: Order?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        amount                          <- map["Amount"]
        comments                        <- map["Comments"]
        couponAdjustmentAmount          <- map["CouponAdjustmentAmount"]
        description                     <- map["Description"]
        displayName                     <- map["DisplayName"]
        firstName                       <- map["FirstName"]
        isFreeShippingOverride          <- map["IsFreeShippingOverride"]
        isMm                            <- map["IsMm"]
        isRefundRequested               <- map["IsRefundRequested"]
        itemAmount                      <- map["ItemAmount"]
        lastCreated                     <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                    <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        mmCouponAdjustmentAmount        <- map["MMCouponAdjustmentAmount"]
        orderCancelItems                <- map["OrderCancelItems"]
        orderCancelKey                  <- map["OrderCancelKey"]
        orderCancelReasonId             <- map["OrderCancelReasonId"]
        orderCancelStatusCode           <- map["OrderCancelStatusCode"]
        orderCancelStatusId             <- map["OrderCancelStatusId"]
        orderCancelStatus               <- (map["OrderCancelStatusId"], EnumTransform<OrderCancelStatus>())
        orderDiscountAdjustmentAmount   <- map["OrderDiscountAdjustmentAmount"]
        orderTransactionKey             <- map["OrderTransactionKey"]
        shippingAdjustmentAmount        <- map["ShippingAdjustmentAmount"]
        userKey                         <- map["UserKey"]
        userName                        <- map["UserName"]
        order                           <- map["Order"]
    }
}
