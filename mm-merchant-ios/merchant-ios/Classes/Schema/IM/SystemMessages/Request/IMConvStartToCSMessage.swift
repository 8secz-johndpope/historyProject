//
//  IMConvStartToCSMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 9/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvStartToCSMessage: IMConvStartMessage {
    
    var merchantId: Int?

    override init() {
        super.init()
    }
    
    convenience init(userList: [UserRole], queue: QueueType, senderMerchantId: Int?, merchantId: Int?) {
        self.init(userList: userList, senderMerchantId: senderMerchantId, queue: queue)
        self.convType = ConvType.Customer
        self.queue = queue
        self.merchantId = merchantId
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        merchantId          <-  map["MerchantId"]
        senderUserKey       <-  map["CustomerKey"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["MerchantId"] = merchantId
        parentJSONObject["CustomerKey"] = senderUserKey
        
        return parentJSONObject
    }
    
}
