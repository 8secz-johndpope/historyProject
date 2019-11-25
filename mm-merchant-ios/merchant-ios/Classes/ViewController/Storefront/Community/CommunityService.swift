//
//  CommunityService.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/8/1.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class CommunityService {
    class func getCommunityData(_ userKey : String, pageno: Int, followingUserKeys: [String]? = nil, followingMerchantIds: [Int]? = nil,success: @escaping ((_ value: NewsFeedListResponse) -> Void),failure: @escaping (_ error: Error) -> Bool) {
        
//        let params: [String : Any] = ["pageno": pageno, "pagesize": pagesize]
        
        var params:[String : Any] = ["pageno": pageno, "pagesize" : Constants.Paging.PostOffset, "userkeytarget": userKey]
        
        if let followUsers = followingUserKeys, followUsers.count > 0 {
            params["followuserlist"] = followUsers.joined(separator: ",")
        }
        
        if let followMerchants = followingMerchantIds, followMerchants.count > 0{
            params["followmerchantlist"] = followMerchants.map{ String($0) }.joined(separator: ",")
        }
        
        let url = Constants.Path.Host + "/search/post"
        
        
        RequestFactory.requestWithObject(.get, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: success, failure: failure)
    }
    
    class func getCommunityFeedData(_ userKey : String, pageno: Int,success: @escaping ((_ value: NewsFeedListResponse) -> Void),failure: @escaping (_ error: Error) -> Bool) {
        
        let params:[String : Any] = ["pageno": pageno, "pagesize" : Constants.Paging.PostOffset,"userkeytarget":userKey]
        let url = Constants.Path.Host + "/search/post"
        
        
        RequestFactory.requestWithObject(.get, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: success, failure: failure)
    }
    

}
