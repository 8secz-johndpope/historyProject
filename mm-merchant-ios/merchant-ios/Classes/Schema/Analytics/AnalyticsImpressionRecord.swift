//
//  AnalyticsImpressionRecord.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AnalyticsImpressionRecord: AnalyticsRecord {
    
    enum ImpressionType: String {
        case Unknown = ""
        case Product = "Product"
    }
    
    var authorRef = ""                                  // GUID or UserKey
    var authorType = ""                                 // Curator, User
    var brandCode = ""
    var impressionRef = ""                              // "NJMU5680" (e.g. Style)
    var impressionType = ""                             // Product
    var impressionKey = ""                              // GUID
    var impressionVariantRef = ""                       // "384720192" (e.g Sku)
    var impressionDisplayName = ""                      // "Multi Stripe Kite Bow Back Dress"
    var merchantCode = ""                               //
    var parentRef = ""                                  //
    var parentType = ""                                 //
    var positionComponent = ""                          // Grid
    var positionIndex = -1                              // 1, 2, 3
    var positionStringIndex = ""                    // use for product banner index : 1-0, 2-0, 3-0
    var positionLocation = ""                           // PLP
    var referrerRef = ""                                // GUID or UserKey or Link definition
    var referrerType = ""                               // Curator, User, Link
    var viewKey = ""                                    // GUID
    var VID = ""                                    // appId.pageId.compId.compIdx.dataType.dataId.dataIdx
    
    override init() {
        super.init()
        type = "i"
    }
    
    override func build() -> [String : Any] {
        let parameters = [
            "ar" : authorRef,
            "at" : authorType,
            "bc" : brandCode,
            "ir" : impressionRef,
            "it" : impressionType,
            "ik" : impressionKey,
            "iv" : impressionVariantRef,
            "id" : impressionDisplayName,
            "mc" : merchantCode,
            "pr" : parentRef,
            "pt" : parentType,
            "pc" : positionComponent,
            "pi" : positionStringIndex.length > 0 ? positionStringIndex : (positionIndex >= 0 ? "\(positionIndex)" : ""), //MM-21145 The position index of TaxInfo of PDP should not be -1
            "pl" : positionLocation,
            "rr" : referrerRef,
            "rt" : referrerType,
            "sk" : sessionKey,
            "ts" : Constants.DateFormatter.getFormatter(.dateAnalytics).string(from: timestamp),
            "ty" : type,
            "vk" : viewKey,
            "vid": VID
        ]
        
        return parameters
    }
}
