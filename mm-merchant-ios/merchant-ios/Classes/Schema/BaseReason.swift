//
//  BaseReason.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 18/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class BaseReason: Mappable {
    
    var isMerchantFault = 0
    var reasonId = 0
    var reasonName = ""
    var reasonNameInvariant = ""
    var reportReasonId = 0
    var reportReasonName = ""
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        isMerchantFault     <-      map["IsMerchantFault"]
        reportReasonId     <-      map["ReportReasonId"]
        reportReasonName     <-      map["ReportReasonName"]
    }
    
}
