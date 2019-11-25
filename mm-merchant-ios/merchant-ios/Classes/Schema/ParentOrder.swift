//
//  ParentOrder.swift
//  merchant-ios
//
//  Created by HungPM on 3/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class ParentOrder: Mappable {
    var parentOrderKey = ""
    var parentOrderStatusId = 0 // TODO: Use enum '1','Closed' / '2','Open' / '3','Initiated' / '4','Expired'
    var isCrossBorder = 0 // >0  说明是海外货物  否则是国内
    var isUserIdentificationExists = false
    var netTotal : Double = 0
    //var grossTotal : Float = 0
    var domesticTotal : Double = 0  // 国内金额支付总额
    var crossBorderTotal : Double = 0 // 国外金额支付总额
    var grandTotal : Double = 0 // 国内 + 国外 支付总金额
    var lastCreated: Date?
    var couponName: String?
    var mmCouponAmount: Double = 0
    var orders : [Order]?

    required convenience init?(map: Map) {
        self.init()
    }
    
    func GMV() -> Double {

        guard let orders = self.orders else {
            return 0
        }

        var gmv: Double = 0
        for order in orders {
            gmv += order.subTotal
            gmv += order.shippingTotal
        }
        
        return gmv
        
    }
   
    
    // Mappable
    func mapping(map: Map) {
        parentOrderKey                  <- map["ParentOrderKey"]
        parentOrderStatusId             <- map["ParentOrderStatusId"]
        isCrossBorder                   <- map["IsCrossBorder"]
        isUserIdentificationExists      <- map["IsUserIdentificationExists"]
        netTotal                        <- map["NetTotal"]
       // grossTotal                      <- map["GrossTotal"]
        domesticTotal                   <- map["DomesticTotal"]
        crossBorderTotal                <- map["CrossBorderTotal"]
        orders                          <- map["Orders"]
        grandTotal                      <- map["GrandTotal"]
        couponName                  <- map["CouponName"]
        mmCouponAmount                  <- map["MMCouponAmount"]
        lastCreated                     <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
    }
}

