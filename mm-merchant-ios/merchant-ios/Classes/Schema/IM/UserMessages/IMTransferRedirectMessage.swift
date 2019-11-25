//
//  IMTransferRedirectMessage.swift
//  merchant-ios
//
//  Created by HungPM on 7/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMTransferRedirectMessage: IMUserMessage {
    
    var merchantId : Int?
    var stayOn: Bool?
    var transferConvKey: String?
    var forwardedMerchantId : Int?

    override init() {
        super.init()
        dataType = .TransferRedirect
    }
    
    convenience init(merchantId: Int, stayOn: Bool, convKey: String, transferConvKey: String, forwardedMerchantId: Int, myUserRole: UserRole?) {
        self.init()
        self.merchantId = merchantId
        self.stayOn = stayOn
        self.convKey = convKey
        self.dataType = .TransferRedirect
        self.transferConvKey = transferConvKey
        self.forwardedMerchantId = forwardedMerchantId

        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ForwardedMerchantId"] = forwardedMerchantId
        parentJSONObject["TransferConvKey"] = transferConvKey
        parentJSONObject["StayOn"] = stayOn

        return parentJSONObject
    }

    override func mapping(map: Map) {
        super.mapping(map: map)
        merchantId          <- map["MerchantId"]
        stayOn              <- map["StayOn"]
        transferConvKey     <- map["TransferConvKey"]
        forwardedMerchantId <- map["ForwardedMerchantId"]
    }
}
