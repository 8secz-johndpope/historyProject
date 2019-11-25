//
//  Curator.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 6/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Curator: NSObject, Mappable  {
    
    var userKey = ""
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

    
    var userName = ""
    var profileImage = ""
    var profileAlternateImage : String?
    var coverAlternateImage : String?
    var followerCount = Int(0)
    
    var image : UIImage?
    var isFollowing = false
    var isLoading = false
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        userKey          <- map["UserKey"]
        _displayName      <- map["DisplayName"]
        userName         <- map["UserName"]
        profileImage     <- map["ProfileImage"]
        followerCount    <- map["FollowerCount"]
        isFollowing      <- map["IsFollowing"]
        coverAlternateImage    <- map["CoverAlternateImage"]
        profileAlternateImage  <- map["ProfileAlternateImage"]
    }
}
