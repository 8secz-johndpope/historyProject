//
//  IMCommentMessage.swift
//  merchant-ios
//
//  Created by hungvo on 20/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

enum CommentStatus : String {
    case Closed = "Closed"
    case Normal = "Normal"
}

class IMCommentMessage: IMUserMessage {
    
    var merchantId : Int?
    var status = CommentStatus.Normal
    
    override init() {
        super.init()
        dataType = .Comment
    }
    
    convenience init(comment: String, merchantId: Int, convKey: String, status: CommentStatus, myUserRole: UserRole?) {
        self.init()
        self.data = comment
        self.merchantId = merchantId
        self.convKey = convKey
        self.dataType = .Comment
        self.status = status
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["MerchantId"] = merchantId
        parentJSONObject["Status"] = status.rawValue
        parentJSONObject["AgentOnly"] = true
        return parentJSONObject
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        merchantId     <-  map["MerchantId"]
        status         <-  map["Status"]
    }
}
