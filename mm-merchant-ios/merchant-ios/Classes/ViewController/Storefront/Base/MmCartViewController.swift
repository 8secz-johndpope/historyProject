//
//  MmCartViewController.swift
//  merchant-ios
//
//  Created by hungvo on 2/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper

class MmCartViewController: MmViewController, MMFloatingActionButtonDelegate {
    
    var startPaymentProcess = false
    var currentType = TypeProfile.Private
    var user: User?
    
    let confirmButton: UIButton = {
        let button = UIButton()
        button.formatPrimary()
        button.setTitle(String.localize("LB_CA_CFM_SORT"), for: UIControlState())
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    

    // MARK: - wishlist cart
    @discardableResult
    func listWishlistItem(_ userKey: String? = nil, saveToCache: Bool = true, completion complete:((_ wishlist: Wishlist?) -> Void)? = nil) -> Promise<Any> {
        return CacheManager.sharedManager.listWishlistItem(userKey, saveToCache: saveToCache, completion: complete)
    }
    
    @discardableResult
    func addWishlistItem(_ merchantId: Int, skuId: Int, isSpecificSku: Bool, referrer: String?) -> Promise<Any> {
        return Promise{ fulfill, reject in
            WishlistService.addItem(merchantId, skuId: skuId, isSpecificSku: isSpecificSku, referrer: referrer, completion:{ (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        // cached it
                        background_async {
                            if let wishlist = Mapper<Wishlist>().map(JSONObject: response.result.value) {
                                wishlist.cartItems?.sort(by: { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending })
                                
                                if LoginManager.getLoginState() == .guestUser {
                                    Context.setAnonymousWishListKey(wishlist.cartKey)
                                    Log.debug("local wishlist cart key: \(wishlist.cartKey)")
                                }
                                
                                CacheManager.sharedManager.wishlist = wishlist
                            }
                            main_async {
                                fulfill("OK")
                            }
                        }
                        
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error!)
                }
            })
        }
    }
    
    @discardableResult
    func removeWishlistItem(_ cartItemId : Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            if cartItemId != NSNotFound {
                WishlistService.removeItem(cartItemId, completion:{ (response) in
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            // cached it
                            background_async {
                                if let wishlist = Mapper<Wishlist>().map(JSONObject: response.result.value) {
                                    wishlist.cartItems?.sort(by: { (DateTransformExtension().transformFromJSON($0.lastModified) ?? Date()).compare((DateTransformExtension().transformFromJSON($1.lastModified) ?? Date())) == .orderedDescending })
                                    CacheManager.sharedManager.wishlist = wishlist
                                }
                                
                                main_async {
                                    fulfill("OK")
                                }
                            }
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }

                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                            
                            self.showErrorAlert(String.localize("LB_CA_DEL_WISHLIST_ITEM_FAILED"))
                        }
                    } else {
                        reject(response.result.error!)
                    }
                })
            }
        }
    }
    
    // MARK: - shopping cart
    func listCartItem(_ success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {
        return CacheManager.sharedManager.listCartItem(success, fail: fail)
    }

    func addCartItem(_ skuId : Int, qty : Int, referrer: String?, success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {
        let promise = Promise<Any> { fulfill, reject in
            CartService.addCartItem(skuId, qty: qty, referrer: referrer, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                            
                            if LoginManager.getLoginState() == .guestUser, let cartKey = cart?.cartKey {
                                Context.setAnonymousShoppingCartKey(cartKey)
                                Log.debug("local shopping cart key: \(cartKey)")
                            }
                            
                            CacheManager.sharedManager.cart = CacheManager.sharedManager.sortCartItems(cart)
                            Context.setVisitedCart(false)
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                            strongSelf.showErrorAlert(String.localize("LB_CA_ADD2CART_FAIL"))
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.showErrorAlert(String.localize("LB_CA_ADD2CART_FAIL"))
                    }
                }
            })
        }
        
        firstly {
            return promise
        }.then { _ -> Void in
            CacheManager.sharedManager.getMerchantInfo(success)
        }.catch { _ -> Void in
            fail?()
        }
    }
    
    func removeCartItem(_ cartItemId : Int, success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {
        let promise = Promise<Any> { fulfill, reject in
            CartService.removeCartItem(cartItemId, completion: { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                        CacheManager.sharedManager.cart = CacheManager.sharedManager.sortCartItems(cart)
                        fulfill("OK")
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                }
                else {
                    reject(response.result.error!)
                }
            })
        }
        
        firstly {
            return promise
        }.then { _ -> Void in
            CacheManager.sharedManager.getMerchantInfo(success)
        }.catch { _ -> Void in
            fail?()
        }
    }

    func updateCartItem(_ cartItemId : Int, skuId : Int, qty : Int, success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {
        let promise = Promise<Any> { fulfill, reject in
            CartService.updateCartItem(cartItemId, skuId: skuId, qty: qty, completion: { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                        CacheManager.sharedManager.cart = CacheManager.sharedManager.sortCartItems(cart)
                        fulfill("OK")
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error!)
                }
            })
        }
        
        firstly {
            return promise
        }.then { _ -> Void in
            CacheManager.sharedManager.getMerchantInfo(success)
        }.catch { _ -> Void in
            fail?()
        }
    }
    
    func moveItemToWishlist(_ cartItemId : Int, isSpecificSku: Bool, success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {
        let promise = Promise<Any> { fulfill, reject in
            CartService.moveItemToWishlist(cartItemId, isSpecificSku: isSpecificSku, completion:{ [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                            
                            if LoginManager.getLoginState() == .guestUser, let wishlistKey = cart?.wishlistKey {
                                Context.setAnonymousWishListKey(wishlistKey)
                                Log.debug("local wishlist cart key: \(wishlistKey)")
                            }

                            CacheManager.sharedManager.cart = CacheManager.sharedManager.sortCartItems(cart)
                            strongSelf.listWishlistItem(completion: { _ in
                                fulfill("OK")
                            })
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            })
        }
        
        firstly {
            return promise
        }.then { _ -> Void in
            CacheManager.sharedManager.getMerchantInfo(success)
        }.catch { _ -> Void in
            fail?()
        }
    }
    
    func addMultiProductToCart(_ listSkuId: [Int], referrer: String?, success: (() -> Void)? = nil, fail: (() -> Void)? = nil) {
        var promiseLit = [Promise<Any>]()
        
        for skuId in listSkuId {
            promiseLit.append(Promise { fulfill, reject in
                CartService.addCartItem(skuId, qty: 1, referrer: referrer, completion: { (response) in
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            // cached it
                            let cart = Mapper<Cart>().map(JSONObject: response.result.value)
                            CacheManager.sharedManager.cart = cart
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                })
            })
        }
        
        when(fulfilled: promiseLit).then { _ -> Void in
            CacheManager.sharedManager.cart = CacheManager.sharedManager.sortCartItems(CacheManager.sharedManager.cart)
            CacheManager.sharedManager.getMerchantInfo(success)
            
            if LoginManager.getLoginState() == .guestUser, let cartKey = CacheManager.sharedManager.cart?.cartKey {
                Context.setAnonymousShoppingCartKey(cartKey)
                Log.debug("local shopping cart key: \(cartKey)")
            }
        }.catch { _ in
            fail?()
        }
    }
    
    func viewDefaultAddress(showDialogError: Bool = true, completion:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            AddressService.viewDefault({ (response) in
                if response.result.isSuccess{
                    if response.response?.statusCode == 200 {
                        if let address = Mapper<Address>().map(JSONObject: response.result.value) {
                            CacheManager.sharedManager.selectedAddress = address
                            fulfill("OK")
                        } else {
                            if showDialogError {
                                self.showError(String.localize("MSG_ERR_CA_SWIPE2PAY_ADDR"), animated: true)
                            }
                        }
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                        
                        if showDialogError {
                            self.showError(String.localize("MSG_ERR_CA_SWIPE2PAY_ADDR"), animated: true)
                        }
                    }
                } else {
                    reject(response.result.error!)
                }
            })
        }
    }
    
    // MARK: - User
    func fetchUserData(_ completion:(() -> Void)? = nil) {
        firstly {
            return fetchUser()
            }.then { _ -> Void in
                if let action = completion{
                    action()
                }
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    private func fetchUser() -> Promise<Any> {
        return Promise{ fulfill, reject in
            UserService.view() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value)!
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
}
