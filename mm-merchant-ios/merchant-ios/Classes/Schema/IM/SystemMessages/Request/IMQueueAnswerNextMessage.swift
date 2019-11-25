//
//  IMQueueAnswerNextMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 10/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMQueueAnswerNextMessage: IMSystemMessage {
    
    var convType = ConvType.Unknown
    var queue = QueueType.Unknown
    var merchantId: Int?
    
    override init() {
        super.init()
        type = .QueueAnswerNext
    }
    
    convenience init(queue: QueueType, merchantId: Int) {
        self.init()
        self.convType = ConvType.Customer
        self.queue = queue
        self.merchantId = merchantId
        self.msgSenderMerchantId = merchantId
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        convType    <-  (map["ConvType"], EnumTransform())
        queue       <-  (map["Queue"], EnumTransform())
        merchantId  <-  map["MerchantId"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvType"] = convType.rawValue
        parentJSONObject["Queue"] = queue.rawValue
        parentJSONObject["MerchantId"] = merchantId
        
        return parentJSONObject
    }
    
}
