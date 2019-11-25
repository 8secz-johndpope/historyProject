//
//  Campaign.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 8/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Campaign: Mappable {
    var campaignKey = ""
    var campaignName = ""
    var availableFrom = Date()
    var availableTo = Date()
    var statusId = 0
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        campaignKey     <- map["CampaignKey"]
        campaignName     <- map["CampaignName"]
        statusId        <- map["StatusId"]
        availableFrom   <-  (map["AvailableFrom"], IMDateTransform(stringFormat: "yyyy-MM-dd'T'HH:mm:ss"))
        availableTo     <-  (map["AvailableTo"], IMDateTransform(stringFormat: "yyyy-MM-dd'T'HH:mm:ss"))
    }

}
