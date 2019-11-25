//
//  IMUserMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 4/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMUserMessage: IMMessage {
    
    var dataType = MessageDataType.Unknown
    var convKey = ""
    var data = ""
    var messageKey: String?
    var agentOnly: Bool?
    
    override init() {
        super.init()
        type = .Message
    }
    
    convenience init(sharable: Sharable, convKey: String) {
        self.init()
        self.data = sharable.getShareKey()
        dataType = sharable.getMessageDataType()
        self.convKey = convKey
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        messageKey      <-  map["MsgKey"]
        dataType        <-  (map["DataType"], EnumTransform())
        convKey         <-  map["ConvKey"]
        data            <-  map["Data"]
        agentOnly       <-  map["AgentOnly"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["MsgKey"] = messageKey
        parentJSONObject["DataType"] = dataType.rawValue
        parentJSONObject["ConvKey"] = convKey
        parentJSONObject["Data"] = data
        
        return parentJSONObject
    }
    
    override func toChatModel() -> ChatModel? {
        let message = ChatModel()
        
        message.messageId = messageKey
        message.chatSendId = senderUserKey
        message.convKey = convKey
        message.timeDate = timestamp
        message.dataType = dataType
        message.correlationKey = correlationKey
        message.agentOnly = agentOnly
        
        // Data must assign last
        message.dataBody = data
        
        return message
    }
}
