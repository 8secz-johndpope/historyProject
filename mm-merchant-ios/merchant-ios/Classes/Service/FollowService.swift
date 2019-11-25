//
//  FollowService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 16/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import PromiseKit


enum FilterUser: Int {
    case getAll = -1,
    getNonCuratorUser = 0,
    getCuratorOnly = 1
}

class FollowService {
    static let FOLLOW_PATH = Constants.Path.Host + "/follow"
    
    static let instance = FollowService()
    
    
    
    // MARK: - Caching users & merchants
    var followingNormalUserKeys = [String]()
    private var followingUserKeys : Set<String>?
    
    var cachedFollowingUserKeys : Set<String> {
        get {
            return followingUserKeys ?? Set([])
        }
        
        set(newFollowingUserKeys) {
            followingUserKeys = newFollowingUserKeys
        }
    }
    
    private var loadingUserKeys : Set<String>?
    
    var cachedLoadingUserKeys : Set<String> {
        get {
            return loadingUserKeys ?? Set([])
        }
        
        set (newLoadingUserKeys) {
            loadingUserKeys = newLoadingUserKeys
        }
    }
    
    private var followingMerchantIds : Set<Int>?
    
    var cachedFollowingMerchantIds : Set<Int> {
        get {
            return followingMerchantIds ?? Set([])
        }
        
        set (newMerchantIds) {
            followingMerchantIds = newMerchantIds
        }
    }
    
    private var loadingMerchantIds : Set<Int>?
    
    var cachedLoadingMerchantIds : Set<Int> {
        get {
            return loadingMerchantIds ?? Set([])
        }
        
        set (newMerchantIds) {
            loadingMerchantIds = newMerchantIds
        }
    }
    
    
    // MARK: - Error Object Creation
    
    class private func getError(_ response : (DataResponse<Any>)) -> NSError {
        var statusCode = 0
        if let code = response.response?.statusCode {
            statusCode = code
        }
        
        var userInfo : [String: Any]?
        if let resp = Mapper<ApiResponse>().map(JSONObject: response.result.value), let appCode = resp.appCode{
            userInfo = ["AppCodeKey": appCode, "data":resp]
        }
        
        return NSError(domain: "", code: statusCode, userInfo: userInfo)
    }
    
    
    
    // MARK: - API Calls
    
    @discardableResult
    class func saveCurator(_ curators : [User], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/user/save"
        var curatorString = ""
        for curator : User in curators {
            curatorString = curatorString + String(curator.userKey) + ","
        }
        curatorString = String(curatorString.dropLast())
        let parameters : [String : Any] = ["ToUserKeys" : curatorString as Any]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func saveMerchant(_ merchants : [Merchant], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/merchant/save"
        var merchantString = ""
        for merchant : Merchant in merchants {
            merchantString = merchantString + String(merchant.merchantId) + ","
        }
        merchantString = String(merchantString.dropLast())
        let parameters : [String : Any] = ["ToMerchantIds" : merchantString as Any]
        let request = RequestFactory.post(url, parameters: parameters,appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func saveBrand(_ toBrandId:Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/brand/save"
       
        let parameters : [String : Any] = ["ToBrandId" : String(toBrandId)]
        let request = RequestFactory.post(url, parameters: parameters,appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func deleteBrand(_ toBrandId:Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/brand/delete"
        
        let parameters : [String : Any] = ["ToBrandId" : String(toBrandId)]
        let request = RequestFactory.post(url, parameters: parameters,appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func deleteMerchant(_ merchant : Merchant, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/merchant/delete"
        let merchantBody = MerchantFollowBody()
        merchantBody.userKey = Context.getUserKey()
        merchantBody.toMerchantId = merchant.merchantId
        return postMerchant(merchantBody, url: url, completion: completion)
    }
    
    @discardableResult
    class private func followMerchant(_ merchant : Merchant, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/merchant/save"
        let merchantBody = MerchantFollowBody()
        merchantBody.userKey = Context.getUserKey()
        merchantBody.toMerchantId = merchant.merchantId
        return postMerchant(merchantBody, url: url, completion: completion)
    }
    
    @discardableResult
    class func listFollowBrand(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/brand/followed"
        let parameters : [String:Any] = ["UserKey" : Context.getUserKey() as Any]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listFollowing(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/user/following"
        let parameters : [String:Any] = ["UserKey" : Context.getUserKey() as Any]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
	
	@discardableResult
    class private func listFollowMerchant(_ start: Int, limit: Int, userKey: String = Context.getUserKey(), completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/merchant/followed?start=\(start)&limit=\(limit)&UserKey=\(userKey)"
        let request = RequestFactory.get(url, parameters: nil, appendUserKey: false)
        request.exResponseJSON {response in completion(response)}
        return request
    }
    
    
    
    @discardableResult
    class func listFollowMerchantByMerchantId(_ start: Int, limit: Int, merchantId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/merchant/following?MerchantId=\(merchantId)&start=\(start)&limit=\(limit)"
        let request = RequestFactory.get(url)
        request.exResponseJSON {response in completion(response)}
        return request
    }
    
    @discardableResult
    class func postMerchant(_ user : MerchantFollowBody, url : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        // create the request & response
        var request = URLRequest(
            url: URL(string: url)!,
            cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData,
            timeoutInterval: 5.0
        )
        
        var token: String = ""
        let tokenModel = Context.getTokenModel()
        if tokenModel.token.length > 0 {
            token = tokenModel.token
        }
        
        // create some JSON data and configure the request
        let jsonString = Mapper().toJSONString(user, prettyPrint: true)
        request.httpBody = jsonString!.data(using: String.Encoding.utf8, allowLossyConversion: true)
        Log.debug(request.httpBody)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        let alamofireRequest = RequestFactory.networkManager.request(request)
        alamofireRequest.exResponseJSON{response in completion(response)}
        return alamofireRequest
    }
    
    @discardableResult
    private class func followUser(_ userKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/user/save"
        let parameters : [String : Any] = ["ToUserKey" : userKey]
        let request = RequestFactory.post(url, parameters: parameters,appendUserKey: true,appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    private class func unfollowUser(_ userKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/user/delete"
        let parameters : [String : Any] = ["ToUserKey" : userKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
	
	@discardableResult
    class func listFollowers(_ start: Int, limit: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
		let url = FOLLOW_PATH + "/user/following?start=\(start)&limit=\(limit)"
		let request = RequestFactory.get(url, parameters: nil, appendUserKey: true)
		request.exResponseJSON {response in completion(response)}
		return request
	}
	
    @discardableResult
    class func listFollowersPublicUser(_ start: Int, limit: Int, useKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FOLLOW_PATH + "/user/following?UserKey=\(useKey)&start=\(start)&limit=\(limit)"
        let request = RequestFactory.get(url, parameters: nil, appendUserKey: false)
        request.exResponseJSON {response in completion(response)}
        return request
    }
    
    @discardableResult
    private class func fetchFollowingUsers(_ isCuratorUser: FilterUser = .getAll, byUserKey: String, start: Int? = nil, limit: Int? = nil, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = FOLLOW_PATH + "/user/followed"
        
        var parameters : [String: Any] = [:]
        
        if isCuratorUser != .getAll {
            parameters["IsCurator"] = isCuratorUser.rawValue
        }
        if let start = start {
            parameters["start"] = start
        }
        if let limit = limit {
            parameters["limit"] = limit
        }
        
        parameters["userkey"] = byUserKey
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON {response in completion(response)}
        return request
    }
    
    
    // MARK: - Promised API Calls
    
    class func listFollowingMerchants(_ start: Int, limit: Int, userKey: String = Context.getUserKey()) -> Promise<[Merchant]> {
        return Promise{ fulfill, reject in
            
            if LoginManager.getLoginState() != .validUser && userKey == Context.getUserKey() {
                fulfill([])
                return
            }
            
            FollowService.listFollowMerchant(start, limit: limit, userKey: userKey, completion: { (response) in
                
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        let merchantList = Mapper<Merchant>().mapArray(JSONObject: response.result.value) ?? []
                        
                        if userKey == Context.getUserKey() {
                            
                            let merchantIds = Set(merchantList.map({ $0.merchantId }))
                            if start == 0 {
                                FollowService.instance.cachedFollowingMerchantIds = merchantIds
                            }else {
                                FollowService.instance.cachedFollowingMerchantIds.formUnion(merchantIds)
                            }

                        }
                        fulfill(merchantList)
                    } else {
                        reject(FollowService.getError(response))
                    }
                } else {
                    reject(response.result.error ?? FollowService.getError(response))
                }
                
            })
        }
    }
    
    
    class func listFollowingUserKeys(useCacheOnlyIfAny userCache: Bool = true) -> Promise<[String]> {
        
        return Promise { fulfill, reject in
            
            if userCache && FollowService.instance.followingUserKeys != nil { //which means we have fetched from server already
                fulfill(Array(FollowService.instance.cachedFollowingUserKeys))
                return
            }
            
            FollowService.listFollowingUsers(.getAll, limit: Constants.Paging.All).then { (_) -> Void in
                fulfill(Array(FollowService.instance.cachedFollowingUserKeys))
            }.catch { (err) in
                reject(err)
            }
        }
    }
    
    class func listFollowingMerchantIds(useCacheOnlyIfAny userCache: Bool = true) -> Promise<[Int]> {
        
        return Promise { fulfill, reject in
            
            if userCache && FollowService.instance.followingMerchantIds != nil { //which means we have fetched from server already
                fulfill(Array(FollowService.instance.cachedFollowingMerchantIds))
                return
            }
            
            FollowService.listFollowingMerchants(0, limit: Constants.Paging.All).then { (_) -> Void in
                fulfill(Array(FollowService.instance.cachedFollowingMerchantIds))
            }.catch { (err) in
                reject(err)
            }
        }
    }
    
    
    class func listFollowingUsers(_ filterUser: FilterUser, byUser: String =  Context.getUserKey(), start: Int? = nil, limit: Int) -> Promise<[User]> {
        
        return Promise{ fulfill, reject in
            
            if LoginManager.getLoginState() != .validUser && byUser == Context.getUserKey() {
                fulfill([])
                return
            }
            
            
            
            FollowService.fetchFollowingUsers(filterUser, byUserKey: byUser, start: start, limit: limit, completion: { (response) in
                
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        let users = Mapper<User>().mapArray(JSONObject: response.result.value) ?? []
                        
                        if byUser == Context.getUserKey() && filterUser == .getAll && limit == Constants.Paging.All {
                            
                            let userKeys = Set(users.map({ $0.userKey }))
                            FollowService.instance.followingNormalUserKeys = users.filter({ $0.isCurator == 0 }).map({ $0.userKey })
                            if start == 0 || start == nil {
                                FollowService.instance.cachedFollowingUserKeys = userKeys
                            }else {
                                FollowService.instance.cachedFollowingUserKeys.formUnion(userKeys)
                            }

                            
                        }
                        fulfill(users)
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error ?? FollowService.getError(response))
                }
                
            })
            
        }
    }
    
    
    class func requestFollow(_ userKey: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FollowService.followUser(userKey, completion: { (response) in
                
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        FollowService.instance.cachedFollowingUserKeys.insert(userKey)
                        FollowService.instance.followingNormalUserKeys.append(userKey)
                        fulfill("OK")
                    } else {
                        let err = getError(response)
                        reject(err)
                    }
                } else {
                    reject(response.result.error!)
                }
                
            })
        }
    }

    
    
    class func requestUnfollow(_ userKey: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FollowService.unfollowUser(userKey, completion: { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        FollowService.instance.cachedFollowingUserKeys.remove(userKey)
                        FollowService.instance.followingNormalUserKeys.remove(userKey)
                        fulfill("OK")
                    } else {
                        let err = getError(response)
                        reject(err)
                    }
                } else {
                    reject(response.result.error!)
                }
            })
        }
    }
    
    
    
    class func requestFollow(merchant: Merchant) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FollowService.followMerchant(merchant) {
                 (response) in
                
                    if response.response?.statusCode == 200 {
                        FollowService.instance.cachedFollowingMerchantIds.insert(merchant.merchantId)
                        
                        fulfill("OK")
                        NotificationCenter.default.post(name: Constants.Notification.followingMerchantDidUpdate, object: merchant)
                    } else {
                        reject(getError(response))
                    }
                
            }
        }
    }
    
    class func requestUnfollow(merchant: Merchant) -> Promise<Any> {
        return Promise{ fulfill, reject in
            FollowService.deleteMerchant(merchant){
                (response) in
                
                if response.response?.statusCode == 200 {
                    FollowService.instance.cachedFollowingMerchantIds.remove(merchant.merchantId)
                    
                    
                    fulfill("OK")
                    NotificationCenter.default.post(name: Constants.Notification.followingMerchantDidUpdate, object: merchant)
                } else {
                    reject(getError(response))
                }
            
            }
        }
    }
    
    class func isFollowing(_ userKey: String) ->Bool {
        return FollowService.instance.cachedFollowingUserKeys.contains(userKey)
    }
}
