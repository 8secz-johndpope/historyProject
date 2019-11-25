//
//  IMPageMessage.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 6/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class IMPageMessage: IMUserMessage {
    override init() {
        super.init()
        dataType = .Magazine
    }
    
    convenience init(contentPageKey: String, convKey: String, myUserRole: UserRole?) {
        self.init()
        self.data = contentPageKey
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
