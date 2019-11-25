//
//  WishlistService.swift
//  merchant-ios
//
//  Created by HungPM on 1/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

class WishlistService {
    static let Path = Constants.Path.Host + "/wishlist"
    
    @discardableResult
    class func addItem(_ merchantId: Int, skuId: Int, isSpecificSku: Bool, referrer: String?, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/item/add"
        var parameters: [String : Any] = ["MerchantId" : merchantId]
        let result: (cartKey: String, isLogin: Bool) = cartKey()
        
        parameters["IsSpecificSku"] = isSpecificSku ? 1 : 0
        
        if skuId != NSNotFound {
            parameters["SkuId"] = skuId
        }
        
        if let _ = referrer {
            parameters["UserKeyReferrer"] = referrer
        }
        
        if !result.isLogin {
            parameters["CartKey"] = result.cartKey
        }
        
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: result.isLogin)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func removeItem(_ cartItemId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/item/remove"
        var parameters: [String : Any] = ["CartItemId" : cartItemId]
        let result: (cartKey: String, isLogin: Bool) = cartKey()
        
        if !result.isLogin {
            parameters["CartKey"] = result.cartKey
        }

        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: result.isLogin)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func userUpdate(_ cartKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/user/update"
        let parameters: [String : Any] = ["CartKey" : cartKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }

    @discardableResult
    class func list(_ userKey: String? = nil, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        var url = ""
        var parameters: [String:Any]? = nil
        let result: (cartKey: String, isLogin: Bool) = cartKey()
        
        if result.isLogin {
            url = Path + "/view/user"
        } else {
            parameters = ["cartkey": result.cartKey as Any]
            url = Path + "/view"
        }

        var request: DataRequest
        
        if let userKey = userKey {
            request = RequestFactory.get(url, parameters: parameters, appendUserKey: false, userKey: userKey)
        } else {
            request = RequestFactory.get(url, parameters: parameters, appendUserKey: result.isLogin)
        }
        
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func listByUser(completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/view/user"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func listByPublicUser(_ publicUser: User, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/view/user?userkey=\(publicUser.userKey)"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func merge(_ cartKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/merge"
        let parameters: [String : Any] = ["MergeCartKey" : cartKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    private class func cartKey() -> (String, Bool) {
        if LoginManager.getLoginState() == .validUser {
            return ("0", true)
        } else {
            var cartKey = "0"
            
            if let key = Context.anonymousWishListKey() {
                cartKey = key
            }
            
            return (cartKey, false)
        }
    }
}
