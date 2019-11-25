//
//  IMQueueRequestConvList.swift
//  merchant-ios
//
//  Created by Kam on 1/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMQueueRequestConvList: IMSystemMessage {
    
    var convType = ConvType.Unknown
    var queue = QueueType.Unknown
    var status = ConvStatus.Unknown
    var state = ConvState.Unknown
    var merchantId: Int?
    
    override init() {
        super.init()
        type = .ConversationList
    }
    
    convenience init(queue: QueueType, status: ConvStatus, state: ConvState,merchantId: Int) {
        self.init()
        self.convType = ConvType.Customer
        self.queue = queue
        self.status = status
        self.state = state
        self.merchantId = merchantId
        self.msgSenderMerchantId = merchantId
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        convType            <-  (map["ConvType"], EnumTransform())
        queue               <-  (map["Queue"], EnumTransform())
        status              <-  (map["Status"], EnumTransform())
        state               <-  (map["State"], EnumTransform())
        merchantId          <-  map["MerchantId"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvType"] = convType.rawValue
        parentJSONObject["Queue"] = queue.rawValue
        parentJSONObject["Status"] = status.rawValue
        parentJSONObject["State"] = state.rawValue
        parentJSONObject["MerchantId"] = merchantId
        
        return parentJSONObject
    }
    
}
