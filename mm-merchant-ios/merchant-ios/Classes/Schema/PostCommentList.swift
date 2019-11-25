//
//  PostCommentList.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/26/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import RealmSwift

class PostCommentList : NSObject, Mappable{
    
    var _displayName: String = ""
    @objc dynamic var displayName: String {
        get {
            if let userAlias = CacheManager.sharedManager.aliasForKey(self.userKey) {
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
    var firstName = ""
    var lastCreated = Date()
    var lastModified = Date()
    var lastName = ""
    var middleName = ""
    var postCommentId : Int?
    var postCommentText = ""
    var postId : Int?
    var profileImage = ""
    var statusId : Int?
    var userId : Int?
    var userKey = ""
    var userName = ""
    var correlationKey : String = Utils.UUID()
    var isCurator: Bool = false
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    
    func mapping(map: Map)
    {
        _displayName <- map["DisplayName"]
        firstName <- map["FirstName"]
        lastName <- map["LastName"]
        middleName <- map["MiddleName"]
        postCommentId <- map["PostCommentId"]
        postCommentText <- map["PostCommentText"]
        postId <- map["PostId"]
        profileImage <- map["ProfileImage"]
        statusId    <- map["StatusId"]
        userId      <- map["UserId"]
        userKey     <- map["UserKey"]
        userName    <- map["UserName"]
        isCurator   <- map["IsCurator"]
        lastCreated   <-  (map["LastCreated"], IMDateTransform(stringFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS"))
        lastModified   <-  (map["LastModified"], IMDateTransform(stringFormat: "yyyy-MM-dd'T'HH:mm:ss.SSS"))
        correlationKey <- map["CorrelationKey"]
        
    }
    
    func getProfileImage() -> String{
        if self.userKey == Context.getUserKey() {
            let profileImage = Context.getUserProfile().profileImage
            if profileImage.length > 0 {
                return profileImage
            }
        }
        return self.profileImage
    }
    
}

