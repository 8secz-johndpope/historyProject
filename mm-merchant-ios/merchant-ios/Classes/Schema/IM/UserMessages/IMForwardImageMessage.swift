//
//  IMForwardImageMessage.swift
//  merchant-ios
//
//  Created by HungPM on 6/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMForwardImageMessage: IMMediaUploadMessage {
    
    var width = CGFloat(0)
    var height = CGFloat(0)
    
    override init() {
        super.init()
    }
    
    convenience init(imageData: String, convKey: String, myUserRole: UserRole?) {
        self.init()
        dataType = .ForwardImage
        self.data = imageData
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    convenience init(localStoreName: String, width: CGFloat, height: CGFloat, convKey: String, myUserRole: UserRole?) {
        self.init()
        dataType = .ForwardImage
        self.localStoreName = localStoreName
        self.width = width
        self.height = height
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["Width"] = width
        parentJSONObject["Height"] = height
        parentJSONObject["AgentOnly"] = true
        
        return parentJSONObject
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        width   <-  map["Width"]
        height  <-  map["Height"]
    }
    
}
