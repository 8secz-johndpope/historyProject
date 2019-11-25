//
//  SocialMessageResponse.swift
//  merchant-ios
//
//  Created by HungPM on 9/13/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class SocialMessageResponse: Mappable {
    
    var hitsTotal = 0
    var pageSize = 0
    var pageCurrent = 0
    var pageTotal = 0
    var pageSuper = false
    var pageData = [SocialMessage]()
    var likeUnreadCount: Int? {
        get {
            return getUnreadCount(.postLiked)
        }
    }
    var commentUnreadCount: Int? {
        get {
            return getUnreadCount(.postComment)
        }
    }
    var followersUnreadCount: Int? {
        get {
            return getUnreadCount(.follow)
        }
    }
    
    func getUnreadCount(_ messageType: SocialMessageType) -> Int {
        var socialMessages = self.pageData.filter{ $0.socialMessageTypeId == messageType }
        socialMessages.sort(by: { $0.lastCreated > $1.lastCreated })
        
        var unread = 0
        for i in 0..<socialMessages.count {
            let isRead = socialMessages[i].isRead
            if isRead == 0 {
                unread += 1
            } else {
                break
            }
        }
        return unread
    }
    
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        hitsTotal               <- map["HitsTotal"]
        pageSize                <- map["PageSize"]
        pageCurrent             <- map["PageCurrent"]
        pageTotal               <- map["PageTotal"]
        pageSuper               <- map["PageSuper"]
        pageData                <- map["PageData"]
    }
}
