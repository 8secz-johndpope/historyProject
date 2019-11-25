//
//  IMConvForwardMessage.swift
//  merchant-ios
//
//  Created by Kam on 3/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvForwardMessage: IMSystemMessage {
    
    var convKey: String?
    var convType = ConvType.Unknown
    var queue = QueueType.Unknown
    var merchantId: Int?
    var senderMerchantId: Int?
    var stayOn: Bool = false
    var agentUserKey: String?
    
    override init() {
        super.init()
        type = .ConversationForward
    }
    
    convenience init(convKey: String, convType: ConvType, queue: QueueType, merchantId: Int, senderMerchantId: Int, stayOn: Bool = false, myUserRole: UserRole?) {
        self.init()
        self.convKey = convKey
        self.convType = convType
        self.queue = queue
        self.merchantId = merchantId
        self.senderMerchantId = senderMerchantId
        self.stayOn = stayOn
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        convKey     <-  map["ConvKey"]
        convType    <-  (map["ConvType"], EnumTransform())
        queue       <-  (map["Queue"], EnumTransform())
        merchantId  <-  map["MerchantId"]
        stayOn      <-  map["StayOn"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvKey"] = JSONOptionalValue(convKey)
        parentJSONObject["ConvType"] = convType.rawValue
        parentJSONObject["Queue"] = queue.rawValue
        parentJSONObject["MerchantId"] = merchantId
        parentJSONObject["StayOn"] = stayOn
        
        return parentJSONObject
    }
    
}
