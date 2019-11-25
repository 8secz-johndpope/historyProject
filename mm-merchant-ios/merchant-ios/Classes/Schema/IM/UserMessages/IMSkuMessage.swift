//
//  IMSkuMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 5/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class IMSkuMessage: IMUserMessage {
    
    override init() {
        super.init()
        dataType = .Sku
    }
    
    convenience init(skuId: String, convKey: String, myUserRole: UserRole?) {
        self.init()
        self.data = skuId
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        let parentJSONObject = super.JSONObject()
        
        return parentJSONObject
    }
}
