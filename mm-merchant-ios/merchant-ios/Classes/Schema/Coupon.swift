//
//  Coupon.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 6/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Coupon: Mappable, CustomDebugStringConvertible {
    
    var couponId = 0
    var couponName = ""
    var couponReference = ""
    var couponAmount: Double = 0
    var minimumSpendAmount : Double = 0
    var statusId: Int?
    var couponDescription = ""
    var isSelected = false
    var availableFrom: Date?
    var availableTo: Date?
    var lastCreated: Date?
    var maximumUserRedemptionsCount: Int?
    var currentUserRedemptionsCount: Int?
    var currentUserPaidCount: Int?
    var claimedTime: Date?
    var merchantId: Int?
    var isSegmented: Int?
    var isPending = false
    private var _segmentMerchantId: Int?
    var segmentBrandId: Int?
    var segmentCategoryId: Int?
    var segmentMerchantId: Int? {
        get {
            if let merchantId = merchantId, let segMerchantId = _segmentMerchantId, merchantId == segMerchantId {
                return nil
            }
            return _segmentMerchantId
        }
        set {
            _segmentMerchantId = newValue
        }
    }
    
    // custom
    var selected = false
    var isClaimed = false
    var isError = false
    var isExpanded = false
    var couponRemark = ""
    
    var isAvailable: Bool {
        get {
            if let status = self.statusId {
                return status == Constants.StatusID.active.rawValue
            }
            return true // if no statusId return then assume server will handle it for us
        }
    }
    var isRedeemable: Bool {
        get {
            if let maxCount = self.maximumUserRedemptionsCount, let currentCount = self.currentUserPaidCount {
                return maxCount - currentCount > 0
            }
            return true
        }
    }
    var isExpired: Bool {
        get {
            if let toDate = self.availableTo {
                return Date() > toDate
            }
            return false
        }
    }
    var isWithinActivePeriod: Bool {
        get {
            if availableFrom == nil && availableTo == nil {
                return true
            }
            
            if let availableFrom = availableFrom, let availableTo = availableTo {
                if availableFrom < Date() && Date() < availableTo {
                    return true
                }
            }
            
            return false
        }
    }
    func isSegmentedFilter(merchantId: Int? = nil, brandId: Int? = nil, categories: [Cat]? = nil) -> Bool {
        if isSegmented != 0 {
            if self.couponId == 1216739 {
                print("")
            }
            var merchantCheck = true
            var brandCheck = true
            var categoryCheck = true
            
            if let segMerchantId = self.segmentMerchantId, segMerchantId != 0, let merchantId = merchantId {
                merchantCheck = (segMerchantId == merchantId)
            }
            
            if let segBrandId = self.segmentBrandId, segBrandId != 0, let brandId = brandId {
                brandCheck = (segBrandId == brandId)
            }
            
            if let segCateId = self.segmentCategoryId, segCateId != 0, let cats = categories {
                var shouldShowCat = false
                for cat in cats {
                    shouldShowCat = (cat.categoryId == segCateId)
                    if shouldShowCat { break }
                }
                categoryCheck = shouldShowCat
            }
            return merchantCheck && brandCheck && categoryCheck
        }
        return true
    }
    func isSegmentedCriteria(merchantId: Int? = nil, brandId: Int? = nil, categories: [Cat]? = nil) -> Bool {

        if isSegmented == 0 {
            return true
        } else {
            var merchantCheck = true
            var brandCheck = true
            var categoryCheck = true
            
            if let segMerchantId = self.segmentMerchantId, segMerchantId != 0, let merchantId = merchantId {
                merchantCheck = (segMerchantId == merchantId)
            }
            
            if let segBrandId = self.segmentBrandId, segBrandId != 0, let brandId = brandId {
                brandCheck = (segBrandId == brandId)
            }
            
            if let segCateId = self.segmentCategoryId, segCateId != 0, let cats = categories {
                var shouldShowCat = false
                for cat in cats {
                    shouldShowCat = (cat.categoryId == segCateId)
                    if shouldShowCat { break }
                }
                categoryCheck = shouldShowCat
            }
            return merchantCheck && brandCheck && categoryCheck
        }
    }
    
    var quickClaimDescription: String {
        if isSegmented == 0 {
            return self.isMmCoupon() ? String.localize("LB_CA_COUPON_QUICK_CLAIM_MM_ALL") : String.localize("LB_CA_COUPON_QUICK_CLAIM_MERCHANT_ALL")
        } else if self.isMmCoupon(), let segMerchantId = self.segmentMerchantId, segMerchantId != 0 {
            guard let segbrandId = self.segmentBrandId, segbrandId != 0, let segCateId = self.segmentCategoryId, segCateId != 0 else {
                return String.localize("LB_CA_COUPON_QUICK_CLAIM_MERCHANT_ALL")
            }
        }
        return String.localize("LB_CA_COUPON_QUICK_CLAIM_PORTION")
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        couponId                      <- map["CouponId"]
        couponReference               <- map["CouponReference"]
        couponName                    <- map["CouponName"]
        couponAmount                  <- map["CouponAmount"]
        minimumSpendAmount            <- map["MinimumSpendAmount"]
        statusId                      <- map["StatusId"]
        availableFrom                 <- (map["AvailableFrom"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateOnlyWithDot, nilFor2038: true))
        availableTo                   <- (map["AvailableTo"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateOnlyWithDot, nilFor2038: true))
        lastCreated                   <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateOnlyWithDot))
        maximumUserRedemptionsCount   <- map["MaximumUserRedemptionsCount"]
        currentUserRedemptionsCount   <- map["CurrentUserRedemptionsCount"]
        currentUserPaidCount          <- map["CurrentUserPaidCount"]
        claimedTime                   <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateOnlyWithDot))
        merchantId                    <- map["MerchantId"]
        isSegmented                   <- map["IsSegmented"]
        isPending                     <- map["IsPending"]
        segmentMerchantId             <- map["SegmentMerchantId"]
        segmentBrandId                <- map["SegmentBrandId"]
        segmentCategoryId             <- map["SegmentCategoryId"]
    }
    
    func isPendingPayment() -> Bool {
        guard let maxCount = self.maximumUserRedemptionsCount, let redeemCount = self.currentUserRedemptionsCount, let paidCount = self.currentUserPaidCount else {
            return false
        }
        
        if maxCount > redeemCount {
            return false
        }
        
        return maxCount != CouponUtils.UnlimitedQuota && redeemCount > paidCount
    }
    
    func isMmCoupon() -> Bool {
        return merchantId == Constants.MMMerchantId
    }
    
    func isNew() -> Bool {
        if let claimedTime = claimedTime {
            let timeInterval = claimedTime.timeIntervalSinceNow
            let hour = -timeInterval / 3600
            
            if hour < 24 {
                return true
            }
        }
        
        return false
    }
    
    func remainingRedemptionCount() -> Int {
        if let maxRedeemCount = maximumUserRedemptionsCount, let currentRedeemCount = currentUserRedemptionsCount {
            let remainCount = maxRedeemCount - currentRedeemCount
            return remainCount >= 0 ? remainCount : 0
        }
        return 0
    }
    
    func eligible() -> Bool {
        
        // status is not 2 ...
        
        if !isAvailable {
            return false
        }
        
        // available time
        
        if isExpired {
            return false
        }
        
        // maximumUserRedemptionsCount > currentUserRedemptionsCount
        
        if !isRedeemable {
            return false
        }
        
        return true

    }
    
    var debugDescription: String {
        return "<MerchantId: \(String(describing: merchantId)), minimumSpendAmount: \(minimumSpendAmount), couponAmount: \(couponAmount), isSegmented: \(String(describing: isSegmented)), segmentMerchantId: \(String(describing: segmentMerchantId)), segmentBrandId: \(String(describing: segmentBrandId)), segmentCategoryId: \(String(describing: segmentCategoryId))>"
    }
}
