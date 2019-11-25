//
//  CartHelper.swift
//  merchant-ios
//
//  Created by HungPM on 2/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire

class CartHelper {
    
    class func upgradeShoppingCart() {
        CartService.viewUser(completion: { (response) in
            let actionHandler = { (response: DataResponse<Any>) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                        CacheManager.sharedManager.cart = CacheManager.sharedManager.sortCartItems(cart)
                        CacheManager.sharedManager.getMerchantInfo()
                    } else {
                        listShoppingCart()
                    }
                    
                    // Remove the guest cart key
                    Context.setAnonymousShoppingCartKey("0")
                }
            }
            
            var isExistingCartKey = false
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    isExistingCartKey = true
                    
                    if let anonymousShoppingCartKey = Context.anonymousShoppingCartKey(), anonymousShoppingCartKey != "0" {
                        CartService.mergeCart(anonymousShoppingCartKey, completion: actionHandler)
                    } else {
                        listShoppingCart()
                    }
                }
            }
            
            if !isExistingCartKey {
                let apiResponse = Mapper<ApiResponse>().map(JSONObject: response.result.value)
                if let res = apiResponse, res.appCode == "MSG_ERR_CART_NOT_FOUND" {
                    if let anonymousShoppingCartKey = Context.anonymousShoppingCartKey(), anonymousShoppingCartKey != "0" {
                        CartService.userUpdate(anonymousShoppingCartKey, completion: actionHandler)
                    } else {
                        listShoppingCart()
                    }
                }
            }
        })
    }
    
    class func upgradeWishList() {
        print("upgradeWishList")
        WishlistService.list(completion: { (response) in
            let actionHandler = { (response: DataResponse<Any>) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let wishList = Mapper<Wishlist>().map(JSONObject: response.result.value) {
                            if let carItems = wishList.cartItems{
                                var _carItems = carItems
                                _carItems.sort(by: { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending })
                                wishList.cartItems = _carItems 
                            }
                            CacheManager.sharedManager.wishlist = wishList
                            
                        }
                    } else {
                        self.listWishListCart()
                    }
                    
                    // Remove the guest wish list key
                    Context.setAnonymousWishListKey("0")
                }
            }
            
            var isExistingWishListKey = false
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    isExistingWishListKey = true
                    
                    if let anonymousWishListCartKey = Context.anonymousWishListKey(), anonymousWishListCartKey != "0" {
                        WishlistService.merge(anonymousWishListCartKey, completion: actionHandler)
                    } else {
                        CartHelper.handleGetWishListSuccess(response)
                    }
                }
            }
            
            if !isExistingWishListKey {
                let apiResponse = Mapper<ApiResponse>().map(JSONObject: response.result.value)
                
                if let res = apiResponse, res.appCode == "MSG_ERR_WISHLIST_NOT_FOUND" {
                    if let anonymousWishListCartKey = Context.anonymousWishListKey(), anonymousWishListCartKey != "0" {
                        WishlistService.userUpdate(anonymousWishListCartKey, completion: actionHandler)
                    } else {
                        CartHelper.handleGetWishListSuccess(response)
                    }
                }
            }
            
        })
    }
    
    class func handleGetWishListSuccess(_ response: DataResponse<Any>){
        if response.result.isSuccess {
            if response.response?.statusCode == 200 {
                if let wishList = Mapper<Wishlist>().map(JSONObject: response.result.value) {
                    wishList.cartItems?.sort(by: { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending })
                    CacheManager.sharedManager.wishlist = wishList
                }
                NotificationCenter.default.post(name: Notification.Name(rawValue: "refreshWishListFinished"), object: nil)
            }
            
            // Remove the guest wish list key
            Context.setAnonymousWishListKey("0")
        }
    }
    
    class func clearShoppingCart() {
        Context.setAnonymousShoppingCartKey("0")
        CacheManager.sharedManager.cart = nil
    }
    
    class func clearWishListCart() {
        Context.setAnonymousWishListKey("0")
        CacheManager.sharedManager.wishlist = nil
    }
    
    private class func listShoppingCart() {
        CartService.list { (response) -> Void in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                    CacheManager.sharedManager.cart = CacheManager.sharedManager.sortCartItems(cart)
                    CacheManager.sharedManager.getMerchantInfo()
                }
                
                // Remove the guest cart key
                Context.setAnonymousShoppingCartKey("0")
            }
        }
    }
    
    private class func listWishListCart() {
        WishlistService.list { (response) -> Void in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let wishList = Mapper<Wishlist>().map(JSONObject: response.result.value) {
                        wishList.cartItems?.sort(by: { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending })
                        CacheManager.sharedManager.wishlist = wishList
                    }
                    
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshWishListFinished"), object: nil)
                }
                
                // Remove the guest wish list cart key
                Context.setAnonymousWishListKey("0")
            }
        }
    }
}
