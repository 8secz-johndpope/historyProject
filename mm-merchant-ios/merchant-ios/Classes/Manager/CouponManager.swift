//
//  CouponManager.swift
//  merchant-ios
//
//  Created by Alan YU on 25/7/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

typealias MerchantId = Int

enum BestCouponCalculationError: Error {
    case calculationTimeout
}

class CouponCache {
    
    var timestamp: TimeInterval
    var coupons: [Coupon]?
    
    init(timestamp: TimeInterval, coupons: [Coupon]?) {
        self.timestamp = timestamp
        self.coupons = coupons
    }
    
    func expired() -> Bool {
        return Date().timeIntervalSince1970 - timestamp > 60 * 35 //35 mins base on server side schedule tasks. Server return coupons which order > 30 mins.
    }
}

typealias CouponResult = (merchantId: Int, coupons: [Coupon]?)

class CouponManager {
    
    private static let instance = CouponManager()
    
    private var availableCouponPool = [Int: CouponCache]()
    private var walletPool = [Int: CouponCache]()
    private var couponRequestPool = [Int: Array<Promise<CouponResult>.PendingTuple>]()
    private var walletRequestPool = [Int: Array<Promise<CouponResult>.PendingTuple>]()
    
    static func shareManager() -> CouponManager {
        return instance
    }
    
    private let fetchingQueue = DispatchQueue(label: "com.mm.CouponFetchingQueue", attributes: [])
    private func RunOnFetchingThread(_ block: @escaping ()->()) {
        fetchingQueue.async(execute: block)
    }

    func coupons(forMerchantId merchantId: Int) -> Promise<CouponResult> {
        let promise = Promise<CouponResult>.pending()
        RunOnFetchingThread {
            if let couponCache = self.availableCouponPool[merchantId], let coupons = couponCache.coupons, !couponCache.expired() {
                Log.debug("Coupon cached merchantId = \(merchantId)")
                promise.fulfill((merchantId: merchantId, coupons: coupons))
            } else {
                let requestHandler = {
                    Log.debug("Coupon request with merchantId = \(merchantId)")
                    let fulfillAll = { (merchantId: Int, coupons : [Coupon]?) in
                        self.RunOnFetchingThread {
                            if let pendingPromiseList = self.couponRequestPool[merchantId] {
                                for promise in pendingPromiseList {
                                    promise.fulfill((merchantId: merchantId, coupons: coupons))
                                }
                                self.couponRequestPool.removeValue(forKey: merchantId)
                            } else {
                                Log.debug("Most likely bug happened!!")
                            }
                        }
                    }
                    CouponService.listCoupon(
                        merchantId,
                        success: { (value) in
                            let coupons = value.pageData
                            self.update(availableCache: merchantId, coupons: coupons)
                            fulfillAll(merchantId, coupons)
                        },
                        failure: { (error) -> Bool in
                            // empty response
                            fulfillAll(merchantId, nil)
                            return false
                        }
                    )
                }
                var inProgress: Bool
                var mutablePendingPromiseList: [Promise<CouponResult>.PendingTuple]
                if let pendingPromiseList = self.couponRequestPool[merchantId] {
                    mutablePendingPromiseList = pendingPromiseList
                    inProgress = true
                } else {
                    mutablePendingPromiseList = []
                    inProgress = false
                }
                mutablePendingPromiseList.append(promise)
                self.couponRequestPool[merchantId] = mutablePendingPromiseList
                
                if !inProgress {
                    requestHandler()
                } else {
                    // waiting for notify
                    Log.debug("Coupon request already fired merchantId = \(merchantId)")
                }
                
            }
        }
        return promise.promise
    }

    func wallet(forMerchantId  merchantId: Int) -> Promise<CouponResult> {
        let promise = Promise<CouponResult>.pending()
        RunOnFetchingThread {
            if let couponCache = self.walletPool[merchantId], let coupons = couponCache.coupons, !couponCache.expired() {
                Log.debug("Coupon cached merchantId = \(merchantId)")
                promise.fulfill((merchantId: merchantId, coupons: coupons))
            } else {
                let requestHandler = {
                    Log.debug("Coupon request with merchantId = \(merchantId)")
                    let fulfillAll = { (merchantId: Int, coupons : [Coupon]?) in
                        self.RunOnFetchingThread {
                            if let pendingPromiseList = self.walletRequestPool[merchantId] {
                                for promise in pendingPromiseList {
                                    promise.fulfill((merchantId: merchantId, coupons: coupons))
                                }
                                self.walletRequestPool.removeValue(forKey: merchantId)
                            } else {
                                Log.debug("Most likely bug happened!!")
                            }
                        }
                    }
                    CouponService.listClaimedCoupon(
                        merchantId,
                        success: { (value) in
                            let coupons = value.pageData?.filter { $0.isAvailable }
                            self.update(walletCache: merchantId, coupons: coupons)
                            fulfillAll(merchantId, coupons)
                        },
                        failure: { (error) -> Bool in
                            // empty response
                            fulfillAll(merchantId, nil)
                            return false
                        }
                    )
                }
                var inProgress: Bool
                var mutablePendingPromiseList: [Promise<CouponResult>.PendingTuple]
                if let pendingPromiseList = self.walletRequestPool[merchantId] {
                    mutablePendingPromiseList = pendingPromiseList
                    inProgress = true
                } else {
                    mutablePendingPromiseList = []
                    inProgress = false
                }
                mutablePendingPromiseList.append(promise)
                self.walletRequestPool[merchantId] = mutablePendingPromiseList
                
                if !inProgress {
                    requestHandler()
                } else {
                    // waiting for notify
                    Log.debug("Coupon request already fired merchantId = \(merchantId)")
                }
                
            }
        }
        return promise.promise
    }
    
    func invalidate(coupons merchantId: Int) -> Void {
        RunOnFetchingThread {
            self.availableCouponPool[merchantId] = nil
        }
    }
    
    func invalidate(wallet merchantId: Int) -> Void {
        RunOnFetchingThread {
            if merchantId != Constants.MMMerchantId {
                self.walletPool[CouponMerchant.allMerchant.rawValue] = nil
                self.walletPool[CouponMerchant.combine.rawValue] = nil
            }
            self.walletPool[merchantId] = nil
        }
    }
    
    func removeAllCouponCache() {
        RunOnFetchingThread {
            self.availableCouponPool.removeAll()
            self.walletPool.removeAll()
        }
    }
    
    private func update(availableCache merchantId: Int, coupons: [Coupon]?) -> Void {
        RunOnFetchingThread {
            let cache = CouponCache(
                timestamp: Date().timeIntervalSince1970,
                coupons: coupons
            )
            self.availableCouponPool[merchantId] = cache
        }
    }
    
    private func update(walletCache merchantId: Int, coupons: [Coupon]?) -> Void {
        RunOnFetchingThread {
            let cache = CouponCache(
                timestamp: Date().timeIntervalSince1970,
                coupons: coupons
            )
            self.walletPool[merchantId] = cache
        }
    }
    
    func calculateTotalDiscount(_ coupons: [Coupon]) -> Double {
        var sum = Double(0)
        for coupon in coupons {
            sum += coupon.couponAmount
        }
        return sum
    }
    
    private func calculateTotalDiscount(_ coupons: [Int: Coupon]) -> Double {
        var sum = Double(0)
        for (_, coupon) in coupons {
            sum += coupon.couponAmount
        }
        return sum
    }
    
    private func getCouponCheckMerchant(_ style: Style, isFlashSale:Bool = false,flashSku:Sku? = nil) -> CouponCheckMerchant {
        var catId : Int? = nil
        if let index = style.categoryPriorityList?.index(where: { $0.level == 2 && $0.priority == 0 }) {
            catId = style.categoryPriorityList?[index].categoryId
        }
        var price = PriceHelper.calculatedPrice(style.priceSale, priceRetail: style.priceRetail, isSale: style.isSale)
        
        if let sku = flashSku {
            if sku.isFlashSaleExists {
                price = sku.priceFlashSale
            } else {
                price = sku.priceRetail
                if sku.isOnSale() {
                    price = sku.priceSale
                }
            }
        }
        
//        if isFlashSale {
//            price = PriceHelper.calculatedPrice(style.priceFlashSale, priceRetail: style.priceRetail, isSale: style.isOnSale())
//        }
        let couponMerchant = CouponCheckMerchant(merchantId: style.merchantId, items: [CouponCheckItem(merchantId: style.merchantId, brandId: style.brandId, categoryId: catId, unitPrice: price, qty: 1)])
        return couponMerchant
    }
    
    // product detail available coupons
    func availableCoupons(_ style: Style) -> Promise<[Coupon]> {
        let checker = self.getCouponCheckMerchant(style)
        let manager = CouponManager.shareManager()
        return self.coupons(forMerchantId: style.merchantId).then { (merchantId, coupons) -> Promise<[Coupon]> in
            Promise(value: coupons?.filter({ manager.eligible(forMerchantCoupon: $0, merchant: checker) }) ?? [])
        }
    }
    
    func PDPAvailableCoupons(_ style: Style) -> Promise<[Coupon]> {
        return self.coupons(forMerchantId: style.merchantId).then { (merchantId, coupons) -> Promise<[Coupon]> in
            Promise(value: coupons ?? [] )
        }
    }
    
    // product detail coupon suggestion
    func calculateBestCoupons(_ style: Style, isFlashSale:Bool = false,flashSku:Sku? = nil) -> Promise<[MerchantId: Coupon]> {
        return self.calculateBestCoupons([self.getCouponCheckMerchant(style, isFlashSale:isFlashSale,flashSku: flashSku)])
    }
    
    private func MerchantFirstBestValue(_ MMCouponList: [Coupon], coupons: [Int: [Coupon]], merchants: [CouponCheckMerchant]) -> (discount: Double, coupons: [Int: Coupon]) {
        
        let bestMerchant = { (coupons: [Int: [Coupon]], merchant: CouponCheckMerchant) -> Coupon? in
            var result: Coupon?
            if let merchantCoupons = coupons[merchant.merchantId] {
                for coupon in merchantCoupons {
                    if self.eligible(forMerchantCoupon: coupon, merchant: merchant) {
                        result = coupon
                        break
                    }
                }
            }
            return result
        }
        
        let bestMM = { (coupons: [Coupon], merchants: [CouponCheckMerchant], merchantMap: [Int: Coupon]) -> Coupon? in
            var result: Coupon?
            for coupon in coupons {
                if self.eligible(forMMCoupon: coupon, merchants: merchants, selectedCoupons: merchantMap) {
                    result = coupon
                    break
                }
            }
            return result
        }
        
        var bestResult = [Int: Coupon]()
        
        for merchant in merchants {
            if let coupon = bestMerchant(coupons, merchant) {
                bestResult[merchant.merchantId] = coupon
            }
        }
        
        if let coupon = bestMM(MMCouponList, merchants, bestResult), let merchantId = coupon.merchantId {
            bestResult[merchantId] = coupon
        }
        
        return (discount: calculateTotalDiscount(bestResult), coupons: bestResult)
    }
    
    func MMFirstBestValue(_ MMCoupons: [Coupon], merchantCoupons: [Int: [Coupon]], merchants: [CouponCheckMerchant], killTime: Date) throws -> (discount: Double, coupons: [Int: Coupon]) {
        
        func testMerchantCoupons(_ selectedCoupons: [Int: Coupon], MMCoupons: [Coupon], merchantCoupons: [[Coupon]], merchants: [CouponCheckMerchant], index: Int, killTime: Date) throws -> (Double, [Int: Coupon]) {
            
            if Date().compare(killTime) == .orderedDescending {
                throw BestCouponCalculationError.calculationTimeout
            }
            
            if merchantCoupons.count == 0 {
                return (0, [:])
            }
            
            if merchantCoupons.count == index { // leaf node
                
                let previousAmount = calculateTotalDiscount(selectedCoupons)
                var bestCoupon: Coupon?
                
                var discount = previousAmount
                var resultCoupons = selectedCoupons
                
                NSLog("\(selectedCoupons)")
                for coupon in MMCoupons {
                    if self.eligible(forMMCoupon: coupon, merchants: merchants, selectedCoupons: selectedCoupons) {
                        let currentAmount = previousAmount + coupon.couponAmount
                        if currentAmount > discount {
                            discount = currentAmount
                            bestCoupon = coupon
                        }
                    }
                }
                
                if let coupon = bestCoupon, let merchantId = coupon.merchantId {
                    resultCoupons[merchantId] = coupon
                }
                
                return (discount, resultCoupons)
                
            } else {
                
                do {
                    
                    // it should always safe since we will stop at coupons.count == index - 1
                    let merchantCouponList = merchantCoupons[index]
                    
                    var (discount, bestCoupons) = try testMerchantCoupons(
                        selectedCoupons,
                        MMCoupons: MMCoupons,
                        merchantCoupons: merchantCoupons,
                        merchants: merchants,
                        index: index + 1,
                        killTime: killTime
                    )
                    
                    // apply each coupon
                    for coupon in merchantCouponList {
                        
                        if let merchantId = coupon.merchantId {
                            
                            // array copy
                            var couponList = selectedCoupons
                            couponList[merchantId] = coupon
                            
                            let (currentDiscount, currentCoupons) = try testMerchantCoupons(
                                couponList,
                                MMCoupons: MMCoupons,
                                merchantCoupons: merchantCoupons,
                                merchants: merchants,
                                index: index + 1,
                                killTime: killTime
                            )
                            
                            if discount < currentDiscount {
                                discount = currentDiscount
                                bestCoupons = currentCoupons
                            }
                            
                        }
                    }
                    
                    return (discount, bestCoupons)
                    
                } catch BestCouponCalculationError.calculationTimeout {
                    throw BestCouponCalculationError.calculationTimeout
                }
                
            }
        }
        
        do {
            
            let (discount, bestResult) = try testMerchantCoupons(
                [:],
                MMCoupons: MMCoupons,
                merchantCoupons: Array(merchantCoupons.values),
                merchants: merchants,
                index: 0,
                killTime: killTime
            )
            
            return (discount: discount, coupons: bestResult)
            
        } catch BestCouponCalculationError.calculationTimeout {
            throw BestCouponCalculationError.calculationTimeout
        }
        
    }

    func calculateBestCoupons(_ merchants: [CouponCheckMerchant]) -> Promise<[MerchantId: Coupon]> {
        return Promise<[MerchantId: Coupon]> { fulfill, reject in
            
            var promise = [Promise<CouponResult>]()
            var merchantMap = [Int: CouponCheckMerchant]()
            
            // array to dict
            for merchant in merchants {
                invalidate(wallet: merchant.merchantId) /* To be test */
                promise.append(wallet(forMerchantId: merchant.merchantId))
                merchantMap[merchant.merchantId] = merchant
            }
            
            // MM coupons
            promise.append(wallet(forMerchantId: 0))
            
            when(fulfilled: promise).then(on: .global()) { (merchantCoupons) -> Void in
                
                // array to dict
                var merchantCouponMap = [Int: [Coupon]]()
                for (merchantId, optionalCoupons) in merchantCoupons {
                    if let coupons = optionalCoupons {
                        merchantCouponMap[merchantId] = coupons
                    }
                }
                
                var merchantMap = [Int: CouponCheckMerchant]()
                
                // array to dict
                for merchant in merchants {
                    merchantMap[merchant.merchantId] = merchant
                }
                
                // sorter
                let sorter = { (c1: Coupon, c2: Coupon) -> Bool in
                    return c1.couponAmount > c2.couponAmount
                }
                
                // sorted and filter mm coupon list
                var MMCoupons = [Coupon]()
                if let coupons = merchantCouponMap[0] {
                    for coupon in coupons {
                        if self.self.eligible(forMMCoupon: coupon, merchants: merchants) {
                            MMCoupons.append(coupon)
                        }
                    }
                }
                MMCoupons.sort(by: sorter)
                
                // create eligible and sorted merchant coupon list
                var filteredMerchantCoupons = [Int : [Coupon]]()
                for merchant in merchants {
                    if let coupons = merchantCouponMap[merchant.merchantId] {
                        var availableCoupons = [Coupon]()
                        for coupon in coupons {
                            if !coupon.isPendingPayment() && self.eligible(forMerchantCoupon: coupon, merchant: merchant) {
                                availableCoupons.append(coupon)
                            }
                        }
                        if availableCoupons.count > 0 {
                            filteredMerchantCoupons[merchant.merchantId] = availableCoupons.sorted(by: sorter)
                        }
                    }
                }
                
                
                let merchantFirst = self.MerchantFirstBestValue(
                    MMCoupons,
                    coupons: filteredMerchantCoupons,
                    merchants: merchants
                )
                
                var bestCoupons = merchantFirst.coupons
                
                do {
                    let killTime = Date().addingTimeInterval(1)
                    let MMFirst = try self.MMFirstBestValue(
                        MMCoupons,
                        merchantCoupons: filteredMerchantCoupons,
                        merchants: merchants,
                        killTime: killTime
                    )
                    
                    if merchantFirst.discount < MMFirst.discount {
                        bestCoupons = MMFirst.coupons
                    }
                    
                } catch BestCouponCalculationError.calculationTimeout {
                    // use merchantFirst logics
                } catch {
                    // further error handle here
                }

                fulfill(bestCoupons)
                
            }
            
        }
    }
    
    ///////////////////////////////////////////////////////////////////////////////////////////
    
    //  Segment
    
    ///////////////////////////////////////////////////////////////////////////////////////////
    
    func eligible(forMerchantCoupon coupon: Coupon, merchant: CouponCheckMerchant) -> Bool {
        return CouponUtils.eligible(forCoupon: coupon, items: merchant.proratedItem())
    }
    
    func eligible(forMMCoupon coupon: Coupon, merchants:[CouponCheckMerchant], selectedCoupons: [Int: Coupon]? = nil /* Assume all coupons are eligible */) -> Bool {
        
        // all items after applied merchant coupon
        var allItems = [ProratedCouponCheckItem]()
        
        for merchant in merchants {
            allItems += merchant.proratedItem(forCoupon: selectedCoupons?[merchant.merchantId])
        }
        
        return CouponUtils.eligible(forCoupon: coupon, items: allItems)
    }
    
    func getCouponRemarkWith(_ merchantId: Int? = nil, brandId: Int? = nil, categoryId: Int? = nil) -> String? {
        
        var remark = ""
        
        if let merchantId = merchantId, let merchantName = CacheManager.sharedManager.cachedMerchantById(merchantId)?.merchantName {
            remark += String.localize("LB_CA_COUPON_SEGMENT_MERC").replacingOccurrences(of: "{0}", with: merchantName) + "\n"
        }
        if let brandId = brandId, let brandName = CacheManager.sharedManager.cachedBrandById(brandId)?.brandName {
            remark += String.localize("LB_CA_COUPON_SEGMENT_BRAND").replacingOccurrences(of: "{0}", with: brandName) + "\n"
        }
        if let categoryId = categoryId, let categoryName = CacheManager.sharedManager.cachedCategoryById(categoryId)?.categoryName {
            remark += String.localize("LB_CA_COUPON_SEGMENT_CAT").replacingOccurrences(of: "{0}", with: categoryName)
        }
        if let categoryId = categoryId, let categoryName = CacheManager.sharedManager.cachedSubcategoryById(categoryId)?.categoryName {
            remark += String.localize("LB_CA_COUPON_SEGMENT_CAT").replacingOccurrences(of: "{0}", with: categoryName)
        }

        if remark.last == "\n" {
            remark = remark.subStringToIndex(remark.length - 1)
        }
        
        return remark.length > 0 ? remark : nil
    }
    
}
