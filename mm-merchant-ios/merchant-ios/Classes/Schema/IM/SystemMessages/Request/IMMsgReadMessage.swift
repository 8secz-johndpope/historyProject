//
//  IMMsgReadMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 10/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMMsgReadMessage: IMSystemMessage {
    
    var msgKey: String?
    
    override init() {
        super.init()
        type = .MessageRead
    }
    
    convenience init(messageKey: String, myUserRole: UserRole?) {
        self.init()
        self.msgKey = messageKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        msgKey     <-  map["MsgKey"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["MsgKey"] = msgKey
        
        return parentJSONObject
    }
    
}
