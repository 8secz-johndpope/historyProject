//
//  IMConvStartMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 5/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvStartMessage: IMSystemMessage {
    
    var userList: [UserRole]?
    var queue = QueueType.Unknown
    var convType = ConvType.Unknown
    
    override init() {
        super.init()
        type = .ConversationStart
    }
    
    convenience init(userList: [UserRole], senderMerchantId: Int?, queue: QueueType? = QueueType.General, convType: ConvType? = ConvType.Private) {
        self.init()
        self.userList = userList
        self.queue = queue!
        self.convType = convType!
        if let senderMerchantId = senderMerchantId {
            self.msgSenderMerchantId = senderMerchantId
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        userList <-  map["UserList"]
        queue    <-  (map["Queue"], EnumTransform())
        convType <-  (map["ConvType"], EnumTransform())
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["UserList"] = JSONUserList(userList)
        parentJSONObject["ConvType"] = convType.rawValue
        parentJSONObject["Queue"] = queue.rawValue
        
        return parentJSONObject
    }
}
