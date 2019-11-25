//
//  IMConvTransferMessage.swift
//  merchant-ios
//
//  Created by HungPM on 7/8/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvTransferMessage: IMSystemMessage {
    
    var convKey: String?
    var queue = QueueType.Unknown
    var merchantId: Int?
    
    override init() {
        super.init()
        type = .ConversationTransfer
    }
    
    convenience init(convKey: String?, queue: QueueType, senderMerchantId: Int? = nil, merchantId: Int?, myUserRole: UserRole?) {
        self.init()
        self.convKey = convKey
        self.queue = queue
        self.merchantId = merchantId
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        convKey             <-  map["ConvKey"]
        merchantId          <-  map["MerchantId"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvKey"] = JSONOptionalValue(convKey)
        parentJSONObject["MerchantId"] = merchantId
        parentJSONObject["Queue"] = queue.rawValue
        parentJSONObject["Type"] = type.rawValue
        
        return parentJSONObject
    }
    
}
