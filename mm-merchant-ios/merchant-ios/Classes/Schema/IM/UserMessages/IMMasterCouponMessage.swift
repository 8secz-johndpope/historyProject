//
//  IMMasterCouponMessage.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 11/15/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class IMMasterCouponMessage: IMUserMessage {
    override init() {
        super.init()
        dataType = .MasterCoupon
    }
    
    convenience init(convKey: String, myUserRole: UserRole?, merchantId: String) {
        self.init()
        
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
        dataType = .MasterCoupon
        self.data = merchantId
    }
    
    override func JSONObject() -> [String : Any] {
        let parentJSONObject = super.JSONObject()
        
        return parentJSONObject
    }

}
