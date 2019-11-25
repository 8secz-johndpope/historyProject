//
//  CouponUtils.swift
//  CouponBestSelection
//
//  Created by Alan YU on 6/8/2017.
//  Copyright © 2017 MyMM. All rights reserved.
//

import Foundation

typealias ProratedCouponCheckItem = (amount: Double, item: CouponCheckItem)

class CouponUtils {
    static let UnlimitedQuota = 999999999
    
    static func eligibleItems(forCoupon coupon: Coupon, items: [ProratedCouponCheckItem]) -> (meet: [ProratedCouponCheckItem], remain: [ProratedCouponCheckItem]) {
        
        // for non-segmented
        var meet = items
        var remain = [ProratedCouponCheckItem]()
        
        if coupon.isSegmented == 1 {
            
            // eligible items
            var segmentedItems = [ProratedCouponCheckItem]()
            
            for item in meet {
                
                // check segmented brand
                if !isEligibleForSegmented(coupon.segmentBrandId, item.item.brandId) {
                    remain.append(item)
                    continue
                }
                
                // check segmented merchant
                if !isEligibleForSegmented(coupon.segmentMerchantId, item.item.merchantId) {
                    remain.append(item)
                    continue
                }
                
                // check segmented category
                if !isEligibleForCategory(coupon.segmentCategoryId, item.item.categoryId) {
                    remain.append(item)
                    continue
                }
                
                segmentedItems.append(item)
            }
            
            meet = segmentedItems
            
        }
        
        return (meet: meet, remain: remain)
    }
    
    static func isEligibleForSegmented(_ couponSegment: Int?, _ itemSegment: Int?) -> Bool {
        if let segment = couponSegment, segment != 0 {
            return itemSegment == segment
        }
        return true
    }
    
    static func isEligibleForCategory(_ couponCategory:Int?, _ styleCategory:Int?) -> Bool  {
        if (isEligibleForSegmented(couponCategory, styleCategory)) {
            return true
        }
        if let styleCategory = styleCategory {
            if let category = CacheManager.sharedManager.cachedSubcategoryById(styleCategory) {
                return isEligibleForSegmented(couponCategory, category.parentCategoryId);
            }
        }
        return false
    }
    

    static func calculateItemsAmount(_ items: [ProratedCouponCheckItem]) -> Double {
        var amount = Double(0)
        for item in items {
            amount += item.amount
        }
        return amount
    }
    
    private static func roundAmount(_ price: Double) -> Double {
        return round(price * 100) / 100
    }
    
    static func eligible(forCoupon coupon: Coupon, items: [ProratedCouponCheckItem]) -> Bool {
        
        if !coupon.eligible() {
            return false
        }
        
        // eligible items
        let (meet, _) = eligibleItems(forCoupon: coupon, items: items)
        
        // check segmented total amount
        let amount = calculateItemsAmount(meet)
        
        return roundAmount(amount) >= roundAmount(coupon.minimumSpendAmount)
        
    }
    
}
