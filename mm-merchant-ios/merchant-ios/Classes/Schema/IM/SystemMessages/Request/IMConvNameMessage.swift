//
//  IMConvNameMessage.swift
//  merchant-ios
//
//  Created by Kam on 3/11/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMConvNameMessage: IMSystemMessage {
    
    var convKey: String?
    var convName: String?
    
    override init() {
        super.init()
        type = .ConvName
    }
    
    convenience init(convKey: String, convName: String?) {
        self.init()
        self.convKey = convKey
        self.convName = convName
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()
        parentJSONObject["ConvKey"] = JSONOptionalValue(convKey)
        parentJSONObject["ConvName"] = JSONOptionalValue(convName)
        
        return parentJSONObject
    }
}
