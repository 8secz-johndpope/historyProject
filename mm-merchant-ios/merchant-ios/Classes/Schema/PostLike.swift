//
//  PostLike.swift
//  merchant-ios
//
//  Created by Tony Fung on 20/5/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//


import UIKit
import ObjectMapper



class PostLike : NSObject, Mappable{
    
    var postLikeId : Int?
    var postId : Int?
    var userKey : String?
    
    var lastCreated = Date()
    var lastModified = Date()
    var correlationKey : String = Utils.UUID()
    var statusId : Int?
    
    var _displayName: String = ""
    @objc dynamic var displayName: String {
        get {
            if let userkey = self.userKey, let userAlias = CacheManager.sharedManager.aliasForKey(userkey) {
                if let aliasStr = userAlias.alias, !aliasStr.isEmpty {
                    return aliasStr
                }
            }
            return self._displayName
        }
        set {
            self._displayName = newValue
        }
    }
    
    var profileImageKey = ""
    
    var isCurator : Bool = false
    required init?(map: Map) {
        super.init()
    }
    
    init(likePost: Post, corrKey: String, userKey: String, status: Int){
        super.init()
        correlationKey = corrKey
        postId = likePost.postId
        lastCreated = Date()
        lastModified = Date()
        statusId = status
    }
    
    func mapping(map: Map)
    {
        lastCreated <- map["LastCreated"]
        lastModified <- map["LastModified"]
        postId <- map["PostId"]
        postLikeId <- map["PostLikeId"]
        statusId <- map["StatusId"]
        lastCreated   <-  (map["LastCreated"], IMDateTransform(stringFormat: "yyyy-MM-dd HH:mm:ss"))
        lastModified   <-  (map["LastModified"], IMDateTransform(stringFormat: "yyyy-MM-dd HH:mm:ss"))
        correlationKey <- map["CorrelationKey"]
        _displayName     <- map["DisplayName"]
        userKey         <- map["UserKey"]
        profileImageKey <- map["ProfileImage"]
        isCurator <- map["IsCurator"]
        
    }
    
}
