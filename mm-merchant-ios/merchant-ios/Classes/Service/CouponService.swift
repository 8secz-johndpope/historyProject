//
//  CouponService.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 6/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//


import Foundation
import Alamofire

enum CouponSortType: String {
    case BestValued = "bestvalued"
    case LastCreated = "lastcreated"
    case CouponAmount = "couponamount"
}

enum CouponMerchant: Int {
    case combine = -2
    case allMerchant = -1
    case mm = 0
}

class CouponService: NSObject {
    
    static let Path = Constants.Path.Host + "/coupon/fe"
    
    class func checkCoupon(_ couponCode: String, merchantId: Int = 0, success: @escaping ((_ value: Coupon) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let url = Path + "/check"
        var parameters: [String: Any] = ["CouponReference" : couponCode as Any]
        
        if merchantId >= 0 {
            parameters["MerchantId"] = "\(merchantId)"
        }
        
        RequestFactory.requestWithObject(.post, url: url, parameters: parameters, success: success, failure: failure)
    }
    
    class func listCoupon(_ merchantId: Int? = nil, success: @escaping ((_ value: CouponList) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let url = Path + "/featured/list"
        
        var parameters: [String: Any]?
        
        if let merchantId = merchantId, merchantId != CouponMerchant.combine.rawValue {
            parameters = ["merchantid" : "\(merchantId)"]
        }

        RequestFactory.requestWithObject(.get, url: url, parameters: parameters, appendUserKey: false, success: success, failure: failure)
    }
    
    class func listClaimedCoupon(_ merchantId: Int? = nil, success: @escaping ((_ value: CouponList) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let url = Path + "/wallet/list"
        
        // server should not cache the response since everyone's are difference
        var parameters: [String: Any] = [
            "lastcouponactiontimestamp": Int(Date().timeIntervalSince1970) as Any
        ]
        
        if let merchantId = merchantId, merchantId != CouponMerchant.combine.rawValue {
            parameters["merchantid"] = "\(merchantId)"
        }
        
        RequestFactory.requestWithObject(.get, url: url, parameters: parameters, success: success, failure: failure)
    }
    
    @discardableResult
    class func claimCoupon(_ couponCode: String, merchantId: Int, complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/queued/claim"
        
        let parameters: [String: Any] = ["CouponCode" : couponCode, "MerchantId" : merchantId]
     
        let request = RequestFactory.post(url, parameters: parameters)
        
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func listValidCoupon(_ styleIds: [Int], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/style/list"
        
        var strStyles = ""
        for styleId in styleIds{
            strStyles = strStyles + styleId.toString() + ","
        }
        strStyles.remove(at: strStyles.index(before: strStyles.endIndex))
        
        let parameters: [String: Any] = ["styleid" : strStyles as Any]
        
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    class func popupCouponList(success: @escaping ((_ value: PopupCoupon) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let url = Constants.Path.Host + "/coupon/unread/list"
//        let request = RequestFactory.post(url, appendUserKey: true)
//        let parameters: [String: Any] = ["ts" : Constants.DateFormatter.getFormatter(.dateAnalytics).string(from: timestamp)]
        RequestFactory.requestWithObject(.post, url: url, appendUserKey: true, appendUserId: false, success: success, failure: failure)
    }
    
    @discardableResult
    class func viewDefault(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/coupon/unread/list"
        let request = RequestFactory.post(url, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
