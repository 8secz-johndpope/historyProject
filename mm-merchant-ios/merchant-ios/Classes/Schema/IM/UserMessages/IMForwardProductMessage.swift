//
//  IMForwardProductMessage.swift
//  merchant-ios
//
//  Created by HungPM on 6/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class IMForwardProductMessage: IMUserMessage {
    
    override init() {
        super.init()
        dataType = .ForwardProduct
    }
    
    convenience init(skuId: String, convKey: String, myUserRole: UserRole?) {
        self.init()
        self.data = skuId
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["AgentOnly"] = true
        
        return parentJSONObject
    }
    
}
