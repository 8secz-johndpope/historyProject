//
//  IMConvRemoveMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 19/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvRemoveMessage: IMSystemMessage {
    
    var convKey: String?
    var userList: [UserRole]?
    
    override init() {
        super.init()
        type = .ConversationRemove
    }
    
    convenience init(convKey: String, userList: [UserRole], myUserRole: UserRole?) {
        self.init()
        self.convKey = convKey
        self.userList  = userList
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        convKey     <-  map["ConvKey"]
        userList    <-  map["UserList"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvKey"] = JSONOptionalValue(convKey)
        parentJSONObject["UserList"] = JSONUserList(userList)
        
        return parentJSONObject
    }
}
