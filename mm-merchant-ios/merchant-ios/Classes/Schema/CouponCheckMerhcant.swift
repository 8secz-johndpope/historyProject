//
//  CouponCheckMerhcant.swift
//  merchant-ios
//
//  Created by Alan YU on 25/7/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class CouponCheckMerchant {
    
    fileprivate(set) var merchantId: Int
    fileprivate(set) var items: [CouponCheckItem]
    
    init(merchantId: Int, items: [CouponCheckItem]) {
        self.merchantId = merchantId
        self.items = items
    }
    
    func proratedItem(forCoupon inCoupon: Coupon? = nil) -> [ProratedCouponCheckItem] {
        
        // transfer to a tuple with amount and item
        var transformedItem = [ProratedCouponCheckItem]()
        for item in items {
            transformedItem.append((amount: item.amount(), item: item))
        }
        
        guard let coupon = inCoupon else {
            return transformedItem
        }
        
        let (meet, remain) = CouponUtils.eligibleItems(forCoupon: coupon, items: transformedItem)
        
        // Prorata the coupon acount to item level
        var discount: Double = 1.0
        if let coupon = inCoupon,  meet.count > 0 {
            discount =  1.0 - coupon.couponAmount / CouponUtils.calculateItemsAmount(meet)
        }
        
        // build result
        var result = [ProratedCouponCheckItem]()
        for item in meet {
            // calculate amount after applied MERCHANT coupon
            result.append((amount: item.amount * discount, item: item.item))
        }
        result += remain
        
        return result
        
    }
    
}
