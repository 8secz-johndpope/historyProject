//
//  IMTextMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 4/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class IMTextMessage: IMUserMessage {
    
    override init() {
        super.init()
        dataType = .Text
    }
    
    convenience init(text: String, convKey: String, myUserRole: UserRole?) {
        self.init()
        self.data = text
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
