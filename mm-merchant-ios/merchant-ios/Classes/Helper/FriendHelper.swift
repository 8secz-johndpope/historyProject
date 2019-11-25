//
//  FriendHelper.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import Alamofire
import PromiseKit

enum StatusFriend:Int {
    case unfriend = 0,
    pending,
    friend,
    receivedFriendRequest
}
enum StatusFollow:Int {
    case unfollow = 0,
    follow
}

class FriendHelper {
    
    class func upgradeFriendsList() {
        var dict = NSMutableDictionary()
        
        FriendService.listFriends(completion: { (response) in
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    let dic = NSMutableDictionary()
                    if let friends = Mapper<User>().mapArray(JSONObject: response.result.value) {
                        CacheManager.sharedManager.friendList = friends
                        for i in 0 ..< friends.count {
                            let user = friends[i]
                            let st: [String: Any] = ["Friend": StatusFriend.friend.rawValue, "Follow": StatusFollow.unfollow.rawValue]
                            let status : NSMutableDictionary = NSMutableDictionary(dictionary: st)
                            dic.setValue(status, forKey: user.userKey)
                        }
                    }
                    dict = dic
                }
                else {
                    
                }
                
            }
            
            FollowService.listFollowingUsers(.getAll, limit: Constants.Paging.All).then { (followingUsers) -> Void in
                let dic = NSMutableDictionary()
                var friends = NSMutableDictionary()
                friends = dict
                for i in 0 ..< followingUsers.count {
                    let follower = followingUsers[i]
                    let friend = friends.value(forKey: follower.userKey) as? NSMutableDictionary
                    if friend != nil {
                        friends.removeObject(forKey: follower.userKey)
                        friend!.setValue(StatusFollow.follow.rawValue, forKey: "Follow")
                    }
                }
                CacheManager.sharedManager.friends = dic
            }
            
            
        })
    }
    class func cleanFriendsList() {
        CacheManager.sharedManager.friends = nil
    }
    
    class func upgradeStatusFriendAndFollow() {
        CacheManager.sharedManager.friends = nil
        self.upgradeFriendsList()
    }
    
    class func getFriendAliasList() {
        UserService.fetchUserAliasList({(response) in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let aliasList = Mapper<UserAlias>().mapArray(JSONObject: response.result.value) {
                        CacheManager.sharedManager.updateAlias(aliasList)
                    }
                }
            }
        })
    }
    
    class func clearFriendAliasList() {
        CacheManager.sharedManager.clearAlias()
    }
}
