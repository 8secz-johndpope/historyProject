//
//  OrderPriceData.swift
//  merchant-ios
//
//  Created by Gambogo on 4/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderPriceData {
    
    var shippingCost = ""
    var grandTotal = ""
    var mmCouponAmount = ""
    var merchantCouponAmount = ""
    var additionalCharge = ""
    var orderDiscount = ""
    
    init (order: Order?) {
        if let order = order {
            if let shippingCost = order.shippingTotal.formatPrice() {
                self.shippingCost = shippingCost
            }
            
            if let grandTotal = order.grandTotal.formatPrice() {
                self.grandTotal = grandTotal
            }
            
            if let mmCouponAmount = (0 - order.mmCouponAmount).formatPrice(), order.mmCouponAmount > 0 {
                self.mmCouponAmount = mmCouponAmount
            }
            
            if let merchantCouponAmount = (0 - order.couponAmount).formatPrice(), order.couponAmount > 0 {
                self.merchantCouponAmount = merchantCouponAmount
            }
            
            if let additionalCharge = order.additionalCharge.formatPrice(), order.additionalCharge > 0 {
                self.additionalCharge = additionalCharge
            }
            
            if let orderDiscount = (0 - order.orderDiscount).formatPrice(), order.orderDiscount > 0 {
                self.orderDiscount = orderDiscount
            }
            
        }
    }
}
