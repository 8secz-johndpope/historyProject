//
//  AnalyticsViewRecord.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AnalyticsViewRecord: AnalyticsRecord {
    
    var authorRef = ""                                  // GUID or UserKey
    var authorType = ""                                 // Curator, User
    var brandCode = ""                                  //
    var merchantCode = ""                               //
    var referrerRef = ""                                // GUID or UserKey or Link definition
    var referrerType = ""                               // Curator, User, Link
    var viewDisplayName = ""                            //
    var viewParameters = ""                             //
    var viewKey = ""                                    // GUID
    var viewLocation = ""                               // PDP
    var viewRef = ""                                    // GUID or "NJMU5588"
    var viewType = ""                                   // Product
    
    override init() {
        super.init()
        type = "v"
    }
    
    override func build() -> [String : Any] {
        let parameters = [
            "ar" : authorRef,
            "at" : authorType,
            "bc" : brandCode,
            "mc" : merchantCode,
            "rr" : referrerRef,
            "rt" : referrerType,
            "sk" : sessionKey,
            "ts" : Constants.DateFormatter.getFormatter(.dateAnalytics).string(from: timestamp),
            "ty" : type,
            "vd" : viewDisplayName,
            "vp" : viewParameters,
            "vk" : viewKey,
            "vl" : viewLocation,
            "vr" : viewRef,
            "vt" : viewType
        ]
        
        return parameters
    }
    
}
