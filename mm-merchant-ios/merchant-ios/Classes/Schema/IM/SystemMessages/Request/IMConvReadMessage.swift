//
//  IMConvReadMessage.swift
//  merchant-ios
//
//  Created by Kam on 24/11/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvReadMessage: IMSystemMessage {
    
    var convKey: String?
    
    override init() {
        super.init()
        type = .ConversationRead
    }
    
    convenience init(convKey: String) {
        self.init()
        self.convKey = convKey
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvKey"] = JSONOptionalValue(convKey)
        
        return parentJSONObject
    }
}
