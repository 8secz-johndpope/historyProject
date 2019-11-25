//
//  IMConvFlagMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 19/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvFlagMessage: IMSystemMessage {
    
    var convKey: String?
    
    override init() {
        super.init()
        type = .ConversationFlag
    }
    
    convenience init(convKey: String, myUserRole: UserRole?) {
        self.init()
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        convKey     <-  map["ConvKey"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvKey"] = JSONOptionalValue(convKey)
        
        return parentJSONObject
    }
    
}
