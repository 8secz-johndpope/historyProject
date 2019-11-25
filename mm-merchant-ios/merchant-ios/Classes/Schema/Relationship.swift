//
//  Relationship.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class Relationship: Mappable {

    var isFollowing = false
    var isFriend = false
    var isFriendRequested = false
    var isFriendRequestReceived = false
    var isFollower = false
    
    var isLoading = false
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        isFollowing                        <- map["IsFollowing"]
        isFriend    <- map["IsFriend"]
        isFriendRequested <- map["IsFriendRequested"]
        isFollower <- map["IsFollower"]
        isFriendRequestReceived <- map["IsFriendRequestReceived"]
    }
}
