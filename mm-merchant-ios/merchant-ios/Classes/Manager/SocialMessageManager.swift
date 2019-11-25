//
//  SocialMessageManager.swift
//  merchant-ios
//
//  Created by HungPM on 9/25/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

let SocialMessageDidUpdateNotification = "SocialMessageDidUpdateNotification"
let SocialMessageUnreadChangedNotification = "SocialMessageUnreadChangedNotification"

class SocialMessageManager {
    class var sharedManager: SocialMessageManager {
        get {
            struct Singleton {
                static let instance = SocialMessageManager()
            }
            return Singleton.instance
        }
    }
    
    var socialMessageUnreadCount: Int {
        get {
            return postLikedUnread + postCommentUnread + followUnread
        }
    }
    
    var postLikedUnread = 0
    var postCommentUnread = 0
    var followUnread = 0
    
    private var fetchingSocialMessage = false

    //private init
    private init() {}

    func getSocialMessageUnreadCount() {
        guard !fetchingSocialMessage else { return }
        
        fetchingSocialMessage = true
        
        var promises = [Promise<Any>]()
        for socialMessageTypeId in SocialMessageType.postLiked.rawValue ... SocialMessageType.follow.rawValue {
            promises.append(
                Promise { fulfill, _ in
                    SocialMessageService.listSocialMessage(socialMessageTypeId, breakCache: true, success: { [weak self] (socialMessageResponse) in
                        if let strongSelf = self {
                            switch socialMessageTypeId {
                            case SocialMessageType.postLiked.rawValue:
                                strongSelf.postLikedUnread = socialMessageResponse.likeUnreadCount ?? 0
                                
                            case SocialMessageType.postComment.rawValue:
                                strongSelf.postCommentUnread = socialMessageResponse.commentUnreadCount ?? 0
                                
                            case SocialMessageType.follow.rawValue:
                                strongSelf.followUnread = socialMessageResponse.followersUnreadCount ?? 0
                                
                            default: break
                            }
                        }
                        fulfill("OK")
                    }, failure: { _ -> Bool in
                        fulfill("OK")
                        return true
                    })
                }
            )
        }
        when(fulfilled: promises).then { _ -> Void in
            PostNotification(SocialMessageUnreadChangedNotification)
            self.fetchingSocialMessage = false
        }
    }
    
    func clearUnreadCount() {
        postLikedUnread = 0
        postCommentUnread = 0
        followUnread = 0
    }
}
