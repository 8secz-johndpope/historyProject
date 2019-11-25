//
//  IMAudioMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 27/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMAudioMessage: IMMediaUploadMessage {
    
    var duration = 0
    
    override init() {
        super.init()
    }
    
    convenience init(audioData: String, convKey: String, myUserRole: UserRole?) {
        self.init()
        dataType = .Audio
        self.data = audioData
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    convenience init(localStoreName: String, duration: Int, convKey: String, myUserRole: UserRole?) {
        self.init()
        dataType = .AudioUUID
        self.localStoreName = localStoreName
        self.duration = duration
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["AudioDuration"] = duration
        
        return parentJSONObject
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        duration     <-  map["AudioDuration"]
    }
    
    override func toChatModel() -> ChatModel? {
        let message = ChatModel()
        
        message.messageId = messageKey
        message.chatSendId = senderUserKey
        message.localStoreName = localStoreName
        message.audioDuration = duration
        message.convKey = convKey
        message.timeDate = timestamp
        message.dataType = dataType
        message.correlationKey = correlationKey
        
        // Data must assign last
        message.dataBody = data
        
        return message
    }
    
    override func mediaFileURL() -> URL? {
        if let localStoreName = self.localStoreName {
            return AudioFilesManager.wavPathWithName(localStoreName)
        }
        return nil
    }
    
}
