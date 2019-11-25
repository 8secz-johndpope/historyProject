//
//  IMImageMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 27/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMImageMessage: IMMediaUploadMessage {
    
    var width = CGFloat(0)
    var height = CGFloat(0)
    
    override init() {
        super.init()
    }
    
    convenience init(imageData: String, convKey: String, myUserRole: UserRole?, agentOnly: Bool? = nil) {
        self.init()
        dataType = .Image
        self.data = imageData
        self.convKey = convKey
        self.agentOnly = agentOnly
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    convenience init(localStoreName: String, width: CGFloat, height: CGFloat, convKey: String, myUserRole: UserRole?, agentOnly: Bool? = nil) {
        self.init()
        dataType = .ImageUUID
        self.localStoreName = localStoreName
        self.width = width
        self.height = height
        self.convKey = convKey
        self.agentOnly = agentOnly
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["Width"] = width
        parentJSONObject["Height"] = height
        if let value = agentOnly {
            parentJSONObject["AgentOnly"] = value
        }
        return parentJSONObject
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        width   <-  map["Width"]
        height  <-  map["Height"]
    }
    
    override func toChatModel() -> ChatModel? {
        let message = ChatModel()
        
        message.messageId = messageKey
        message.chatSendId = senderUserKey
        message.localStoreName = localStoreName
        message.imageWidth = width
        message.imageHeight = height
        message.convKey = convKey
        message.timeDate = timestamp
        message.dataType = dataType
        message.correlationKey = correlationKey
        
        // Data must assign last
        message.dataBody = data
        
        return message
    }
    
    override func mediaFileURL() -> URL? {
       if let localStoreName = self.localStoreName, let filePath = ImageFilesManager.cachePathForKey(localStoreName) {
            return URL(fileURLWithPath: filePath)
        }
        return nil
    }
    
}
