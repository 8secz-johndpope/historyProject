//
//  AnalyticsCampaignRecord.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class AnalyticsCampaignRecord: AnalyticsRecord {
    
    var campaignKey = ""
    var campaignCode = ""
    var campaignSource = ""
    var campaignMedium = ""
    var campaignUserKey = ""
    
    
    override init() {
        super.init()
        type = "c"
    }
    
    override func build() -> [String : Any] {
        let parameters = [
            "ck" : campaignKey,
            "co" : campaignCode,
            "cs" : campaignSource,
            "cm" : campaignMedium,
            "ca" : campaignUserKey,
            "sk" : sessionKey,
            "ts" : Constants.DateFormatter.getFormatter(.dateAnalytics).string(from: timestamp),
            "ty" : type,
            "ct" : ""

        ]
        
        return parameters as [String : String]
    }

}
