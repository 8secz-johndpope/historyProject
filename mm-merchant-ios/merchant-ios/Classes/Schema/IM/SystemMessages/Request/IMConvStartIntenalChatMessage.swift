//
//  IMConvStartIntenalChatMessage.swift
//  merchant-ios
//
//  Created by Kam on 20/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvStartIntenalChatMessage: IMConvStartToCSMessage {
    
    override init() {
        super.init()
    }
    
    convenience init(userList: [UserRole], senderMerchantId: Int?, merchantId: Int?) {
        self.init(userList: userList, queue: QueueType.General, senderMerchantId: senderMerchantId, merchantId: merchantId)
        self.convType = ConvType.Internal
        self.merchantId = merchantId
        if let senderMerchantId = senderMerchantId {
            self.msgSenderMerchantId = senderMerchantId
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
    }
    
    override func JSONObject() -> [String : Any] {
        let parentJSONObject = super.JSONObject()
        
        return parentJSONObject
    }
    
}
