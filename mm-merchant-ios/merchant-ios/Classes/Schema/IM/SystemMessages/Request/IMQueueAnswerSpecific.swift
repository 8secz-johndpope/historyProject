//
//  IMQueueAnswerSpecific.swift
//  merchant-ios
//
//  Created by Kam on 1/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMQueueAnswerSpecific: IMSystemMessage {
    
    var convKey: String?
    var convType = ConvType.Unknown
    var queue = QueueType.Unknown
    var merchantId: Int?
    
    override init() {
        super.init()
        type = .QueueAnswerSpecific
    }
    
    convenience init(convKey: String, queue: QueueType, merchantId: Int) {
        self.init()
        self.convKey = convKey
        self.convType = ConvType.Customer
        self.queue = queue
        self.merchantId = merchantId
        self.msgSenderMerchantId = merchantId
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        convKey     <-  map["ConvKey"]
        convType    <-  (map["ConvType"], EnumTransform())
        queue       <-  (map["Queue"], EnumTransform())
        merchantId  <-  map["MerchantId"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvKey"] = JSONOptionalValue(convKey)
        parentJSONObject["ConvType"] = convType.rawValue
        parentJSONObject["Queue"] = queue.rawValue
        parentJSONObject["MerchantId"] = merchantId
        
        return parentJSONObject
    }
}
