//
//  AnalyticsRecord.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AnalyticsRecord {
    
    var sessionKey = ""                                 // GUID
    var timestamp = Date()                            // 2016-07-11T16:11:06.800Z
    var type = ""
    
    func build() -> [String : Any] {
        let parameters: [String : Any] = [
            "sk" : sessionKey as Any,
            "ts" : Constants.DateFormatter.getFormatter(.dateAnalytics).string(from: timestamp),
            "ty" : type,
        ]
        
        return parameters
    }
    
}
