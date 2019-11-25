//
//  FriendService.swift
//  merchant-ios
//
//  Created by HVN_Pivotal on 3/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

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

class FriendService {
    static let FRIEND_PATH = Constants.Path.Host + "/friend"
        
    @discardableResult
    class func listFriends(completion complete : @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FRIEND_PATH + "/list"
        let request = RequestFactory.get(url)
        request.exResponseJSON{ response in complete(response)}
        return request
    }
    
    @discardableResult
    class func findFriend(_ s : String, limit : Int, startFrom : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FRIEND_PATH + "/find"
        let parameters : [String : Any] = ["s" : s, "limit" : limit, "start" : startFrom]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listRequest(completion complete : @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FRIEND_PATH + "/request/receive"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func acceptRequest(_ friend : User, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FRIEND_PATH + "/request/accept"
        let parameters : [String : Any] = ["ToUserKey" : friend.userKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func deleteRequest(_ friend : User, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FRIEND_PATH + "/delete"
        let parameters : [String : Any] = ["ToUserKey" : friend.userKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func addFriendRequest(_ friend : User, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FRIEND_PATH + "/request"
        let parameters : [String : Any] = ["ToUserKey" : friend.userKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func cancelFriend(_ friend : User, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = FRIEND_PATH + "/request/delete"
        let parameters : [String : Any] = ["ToUserKey" : friend.userKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }

}
