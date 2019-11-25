//
//  IMContactMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 5/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class IMContactMessage: IMUserMessage {
    
    override init() {
        super.init()
        dataType = .User
    }
    
    convenience init(userKey: String, convKey: String, myUserRole: UserRole?) {
        self.init()
        self.data = userKey
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
