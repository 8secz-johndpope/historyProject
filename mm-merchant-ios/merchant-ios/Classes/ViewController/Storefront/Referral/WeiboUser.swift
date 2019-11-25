//
//  WeiboUser.swift
//  merchant-ios
//
//  Created by Tony Fung on 12/6/2017.
//  Copyright © 2017年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper


/*
 
 "id": 1404376560,
 "screen_name": "zaku",
 "name": "zaku",
 "province": "11",
 "city": "5",
 "location": "北京 朝阳区",
 "description": "人生五十年，乃如梦如幻；有生斯有死，壮士复何憾。",
 "url": "http://blog.sina.com.cn/zaku",
 "profile_image_url": "http://tp1.sinaimg.cn/1404376560/50/0/1",
 "domain": "zaku",
 "gender": "m",
 "followers_count": 1204,
 "friends_count": 447,
 "statuses_count": 2908,
 "favourites_count": 0,
 "created_at": "Fri Aug 28 00:00:00 +0800 2009",
 "following": false,
 "allow_all_act_msg": false,
 "geo_enabled": true,
 "verified": false,
 "status": {
 "created_at": "Tue May 24 18:04:53 +0800 2011",
 "id": 11142488790,
 "text": "我的相机到了。",
 "source": "<a href="http://weibo.com" rel="nofollow">新浪微博</a>",
 "favorited": false,
 "truncated": false,
 "in_reply_to_status_id": "",
 "in_reply_to_user_id": "",
 "in_reply_to_screen_name": "",
 "geo": null,
 "mid": "5610221544300749636",
 "annotations": [],
 "reposts_count": 5,
 "comments_count": 8
 },
 "allow_all_comment": true,
 "avatar_large": "http://tp1.sinaimg.cn/1404376560/180/0/1",
 "verified_reason": "",
 "follow_me": false,
 "online_status": 0,
 "bi_followers_count": 215
 
 */





class WeiboUser: Mappable {
    
    
    var userID = ""
    var userClass = ""
    var screenName = ""
    var name = ""
    var province = ""
    var city = ""
    var location = ""
    var userDescription = ""
    var url = ""
    var profileImageUrl = ""
    var coverImageUrl = ""
    var coverImageForPhoneUrl = ""
    var profileUrl = ""
    var userDomain = ""
    var weihao = ""
    var gender = ""
    var followersCount = 0
    var friendsCount = 0
    var pageFriendsCount = 0
    var statusesCount = 0
    var favouritesCount = 0
    var createdTime = ""
    var isFollowingMe = false
    var isFollowingByMe = false
    var isAllowAllActMsg = false
    var isAllowAllComment = false
    var isGeoEnabled = false
    var isVerified = false
    var verifiedType = ""
    var remark = ""
    var statusID = ""
    var ptype = ""
    var avatarLargeUrl = ""
    var avatarHDUrl = ""
    var verifiedReason = ""
    var verifiedTrade = ""
    var verifiedReasonUrl = ""
    var verifiedSource = ""
    var verifiedSourceUrl = ""
    var verifiedState = ""
    var verifiedLevel = ""
    var onlineStatus = ""
    var biFollowersCount = ""
    var language = ""
    var star = ""
    var mbtype = ""
    var mbrank = ""
    var block_word = ""
    var block_app = ""
    var credit_score = ""
    var originParaDict = [String: Any]()

    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
    
        userID <- map["id"]
        screenName <- map["screen_name"]
        name <- map["name"]
        province  <- map["province"]
        city <- map["city"]
        location  <- map["location"]
        userDescription  <- map["description"]
        url      <- map["url"]
        profileImageUrl <- map["profile_image_url"]
        userDomain  <- map["domain"]
        gender <- map["gender"]
        followersCount  <- map["followers_count"]
        friendsCount  <- map["friends_count"]
        statusesCount  <- map["statuses_count"]
        favouritesCount  <- map["favourites_count"]
        createdTime  <- map["created_at"]
        isFollowingByMe  <- map["following"]
        isAllowAllActMsg <- map["allow_all_act_msg"]
        isGeoEnabled  <- map["geo_enabled"]
        isVerified  <- map["verified"]
        statusID    <- map["status"]["id"]
        isAllowAllComment <- map["allow_all_comment"]
        avatarLargeUrl <- map["avatar_large"]
        verifiedReason <- map["verified_reason"]
        isFollowingMe <- map["follow_me"]
        onlineStatus <- map["online_status"]
        biFollowersCount <- map["bi_followers_count"]
    }
    
}
