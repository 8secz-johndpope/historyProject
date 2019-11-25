//
//  IMPostMessage.swift
//  merchant-ios
//
//  Created by Tony Fung on 14/6/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import UIKit

class IMPostMessage: IMUserMessage {

    
    override init() {
        super.init()
        dataType = .NewsFeedPost
    }
    
    convenience init(postId: Int, convKey: String, myUserRole: UserRole?) {
        self.init()
        self.data = String(postId) 
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        let parentJSONObject = super.JSONObject()
        
        return parentJSONObject
    }
    
}
