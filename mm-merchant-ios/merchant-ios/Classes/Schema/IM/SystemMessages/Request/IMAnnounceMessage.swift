//
//  IMAnnounceMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 4/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMAnnounceMessage: IMSystemMessage {
    
    var senderMerchantList: [Int]?
    
    override init() {
        super.init()
        type = .Announce
    }
    
    convenience init(senderMerchantList: [Int]?) {
        self.init()
        self.senderMerchantList = senderMerchantList
        self.includeSenderMerchantId = false
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        senderMerchantList <- map["SenderMerchantList"]
    }
    
    override func JSONString() -> String? {
        let json: [String: Any] = [
            "Type":                 type.rawValue as Any,
            "Token":                Context.getToken() as Any,
            "SenderUserKey":        senderUserKey as Any,
            "SenderMerchantList":   JSONOptionalValue(senderMerchantList, defaultValue: []),
            "SenderMerchantId":     JSONOptionalValue(nil),
            "CorrelationKey":       correlationKey
        ]
        return convertObjectToJSONString(json)
    }
    
}
