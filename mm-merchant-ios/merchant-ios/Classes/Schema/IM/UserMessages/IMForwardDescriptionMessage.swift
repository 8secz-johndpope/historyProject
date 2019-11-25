//
//  IMForwardDescriptionMessage.swift
//  merchant-ios
//
//  Created by HungPM on 6/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMForwardDescriptionMessage: IMUserMessage {
    
    var merchantId : Int?
    var status = CommentStatus.Normal
    var forwardedMerchantId : Int?
    var forwardedMerchantQueueName : QueueType?
    
    override init() {
        super.init()
        dataType = .ForwardDescription
    }
    
    convenience init(comment: String, merchantId: Int, convKey: String, status: CommentStatus, dataType: MessageDataType = .ForwardDescription, forwardedMerchantId: Int, forwardedMerchantQueueName: QueueType, myUserRole: UserRole?) {
        self.init()
        self.data = comment
        self.merchantId = merchantId
        self.convKey = convKey
        self.dataType = dataType
        self.status = status
        self.forwardedMerchantId = forwardedMerchantId
        self.forwardedMerchantQueueName = forwardedMerchantQueueName

        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["MerchantId"] = merchantId
        parentJSONObject["Status"] = status.rawValue
        parentJSONObject["ForwardedMerchantId"] = forwardedMerchantId
        parentJSONObject["ForwardedMerchantQueueName"] = forwardedMerchantQueueName?.rawValue
        parentJSONObject["AgentOnly"] = true
        
        return parentJSONObject
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        merchantId                  <- map["MerchantId"]
        status                      <- map["Status"]
        forwardedMerchantId         <- map["ForwardedMerchantId"]
        forwardedMerchantQueueName  <- (map["ForwardedMerchantQueueName"], EnumTransform())
    }
}
