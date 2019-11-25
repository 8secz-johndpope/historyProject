//
//  IMRefundMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 16/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMRefundMessage: IMOrderMessage {
    
    var refundNumber: String?
    
    override init() {
        super.init()
        dataType = .Refund
    }
    
    convenience init(orderNumner: String, refundNumber: String, items: [Int], convKey: String, myUserRole: UserRole?) {
        self.init()
//        self.orderNumner = orderNumner
        self.refundNumber = refundNumber
//        self.items = items
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["RefundNumber"] = refundNumber
        
        return parentJSONObject
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        refundNumber  <-  map["RefundNumber"]
    }
    
}
