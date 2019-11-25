//
//  IMMsgListRequestMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 5/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMMsgListRequestMessage: IMSystemMessage {
    
    var convKey: String?
    var pageStart: Date?
    var pageLimit: Int = Constants.Paging.Offset
    
    override init() {
        super.init()
        type = .MessageList
    }
    
    convenience init(convKey: String, myUserRole: UserRole?, pageStart: Date? = nil) {
        self.init()
        self.convKey = convKey
        self.pageStart = pageStart
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        convKey     <-  map["ConvKey"]
        pageStart   <-  (map["PageStart"], IMDateTransform())
        pageLimit   <-  map["PageLimit"]
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvKey"] = JSONOptionalValue(convKey)
        parentJSONObject["PageStart"] = IMDateTransform().transformToJSON(pageStart)
        parentJSONObject["PageLimit"] = pageLimit
        
        return parentJSONObject
    }
    
}
