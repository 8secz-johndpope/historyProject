//
//  MmContactViewController.swift
//  merchant-ios
//
//  Created by HungPM on 6/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Alamofire

class MmContactViewController: MmViewController {
    
    func listFriends() -> Promise<[User]> {
        return Promise<[User]> { fulfill, reject in
            FriendService.listFriends() {
                (response) in
                if response.result.isSuccess && response.response?.statusCode == 200 {
                    let friends = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                    fulfill(friends)
                }
                else {
                    reject(response.result.error!)
                }
            }
        }
    }

    func listFriendRequest() -> Promise<[User]> {
        return Promise { fulfill, reject in
            FriendService.listRequest() {
                (response) in
                if response.result.isSuccess && response.response?.statusCode == 200 {
                    let friendRequests = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                    fulfill(friendRequests)
                }
                else {
                    reject(response.result.error!)
                }
            }
        }
    }
        
    func listMerchantAgent(_ merchantId: Int = -1) -> Promise<[User]> {
        return Promise { fulfill, reject in
            UserService.merchantContactList(merchantId, success: { (merchants) in
                fulfill(merchants)
                }, failure: { (error) -> Bool in
                    reject(error)
                    return false
            })
        }
    }
    
    func listMMAgent() -> Promise<[Merchant]> {
        return Promise { fulfill, reject in
            UserService.mmContactList() {
                (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        let agents = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                        
                        let mmMerchant = Merchant.MM()
                        mmMerchant.users = agents
                        
                        fulfill([mmMerchant])
                    }
                }
                else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
    func listMerchant() -> Promise<[Merchant]> {
        
        return Promise { fulfill, reject in
            MerchantService.fetchMerchantsIfNeeded(.all).then { (merchants) -> Void in
                
                fulfill(merchants)
                
            }.catch { (error) -> Void in
                
                reject(error)
            }
    
        }
    }
    
}
