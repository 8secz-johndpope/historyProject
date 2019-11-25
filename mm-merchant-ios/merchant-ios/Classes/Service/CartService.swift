//
//  CartService.swift
//  merchant-ios
//
//  Created by HungPM on 1/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

class CartService {
    
    static let CART_PATH = Constants.Path.Host + "/cart"
    
    class func createCart(completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = CART_PATH + "/create"
        let request = RequestFactory.post(url)
        request.exResponseJSON{response in complete(response)}
        return request
    }

    @discardableResult
    class func updateCartItem(_ cartItemId : Int, skuId : Int, qty : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = CART_PATH + "/item/update"
        var parameters : [String:Any] = ["CartItemId":cartItemId, "SkuId":skuId, "Qty":qty]

        let result : (cartKey: String, isLogin: Bool) = cartKey()
        
        if !result.isLogin {
            parameters["CartKey"]  = result.cartKey
        }

        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: result.isLogin ? true : false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func removeCartItem(_ cartItemId : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = CART_PATH + "/item/remove"
        var parameters : [String:Any] = ["CartItemId":cartItemId]
        
        let result : (cartKey: String, isLogin: Bool) = cartKey()
        
        if !result.isLogin {
            parameters["CartKey"] = result.cartKey
        }

        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: result.isLogin ? true : false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func addCartItem(_ skuId : Int, qty : Int, referrer : String?, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = CART_PATH + "/item/add"
        var parameters : [String:Any] = ["SkuId":skuId, "Qty":qty]
        
        if let _ = referrer {
            parameters["UserKeyReferrer"] = referrer
        }
        
        let result : (cartKey: String, isLogin: Bool) = cartKey()
        
        if !result.isLogin {
            parameters["CartKey"] = result.cartKey
        }

        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: result.isLogin ? true : false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func list(completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        var url : String!
        var parameters : [String:Any]? = nil
        
        let result : (cartKey: String, isLogin: Bool) = cartKey()
        
        if result.isLogin {
            url = CART_PATH + "/view/user"
        }
        else {
            parameters = ["cartkey": result.cartKey as Any]
            url = CART_PATH + "/view"
        }

        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: result.isLogin ? true : false)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func mergeCart(_ mergeCartKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = CART_PATH + "/merge"
        let parameters : [String:Any] = ["MergeCartKey":mergeCartKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func viewUser(completion complete : @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = CART_PATH + "/view/user"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func userUpdate(_ cartKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = CART_PATH + "/user/update"
        let parameters : [String:Any] = ["CartKey" : cartKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func moveItemToWishlist(_ cartItemId : Int, isSpecificSku: Bool, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = CART_PATH + "/item/move/wishlist"
        var parameters: [String : Any] = ["CartItemId" : cartItemId]
        
        if isSpecificSku {
            parameters["IsSpecificSku"] = 1
        } else {
            parameters["IsSpecificSku"] = 0
        }
        
        let result : (cartKey: String, isLogin: Bool) = cartKey()
        
        if !result.isLogin {
            parameters["CartKey"] = result.cartKey
            
            let wishlistKey = wishlistCartKey()
            if wishlistKey != "0" {
                parameters["WishlistKey"] = wishlistKey
            }
        }
        
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: result.isLogin ? true : false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    private class func cartKey() -> (String, Bool) {
        if LoginManager.getLoginState() == .validUser {
            return ("0", true)
        }
        else {
            var cartKey = "0"
            if let cKey = Context.anonymousShoppingCartKey() {
                cartKey = cKey
            }
            return (cartKey, false)

        }
    }
    
    private class func wishlistCartKey() -> String {
        var wishListKey = "0"
        
        if LoginManager.getLoginState() != .validUser, let key = Context.anonymousWishListKey() {
            wishListKey = key
        }
        return wishListKey
        
    }
    
}
