//
//  Loyalty.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/27/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

enum LoyaltyStatusCodeLevel: String {
    case standard = "STANDARD"
    case ruby = "RUBY"
    case silver = "SILVER"
    case gold = "GOLD"
    case platinum = "PLATINUM"
}

class Loyalty : Mappable{
    var loyaltyStatusId = 0
    var loyaltyStatusCode = ""
    var pushTranslationCode = ""
    var loyaltyStatusName = ""
    var loyaltyStatusNameInvariant = ""
    var minimumPaymentTotal = 0.0
    var lastModified = ""
    var lastCreated = ""
    var iconUrl = ""
    var sliderUrl = ""
    var titleTranslationCode = ""
    var subtitleTranslationCode = ""
    var privilegeIds = [Int]()
    var loyaltyPrivileges = [LoyaltyPrivilege]()
    var footers = [LoyaltyFooter]()
    var quota = 0
    // Custom
    var memberLoyaltyStatusName: String{
        return loyaltyStatusName + String.localize("LB_CA_MEMBERSHIP")
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        loyaltyStatusId                 <- map["LoyaltyStatusId"]
        loyaltyStatusCode               <- map["LoyaltyStatusCode"]
        pushTranslationCode             <- map["PushTranslationCode"]
        loyaltyStatusName               <- map["LoyaltyStatusName"]
        loyaltyStatusNameInvariant      <- map["LoyaltyStatusNameInvariant"]
        minimumPaymentTotal             <- map["MinimumPaymentTotal"]
        lastModified                    <- map["LastModified"]
        lastCreated                     <- map["LastCreated"]
        iconUrl                         <- map["IconUrl"]
        sliderUrl                       <- map["SliderUrl"]
        titleTranslationCode            <- map["TitleTranslationCode"]
        subtitleTranslationCode         <- map["SubtitleTranslationCode"]
        privilegeIds                    <- map["PrivilegeIds"]
        loyaltyPrivileges               <- map["Privileges"]
        footers                         <- map["Footers"]
        quota                           <- map["Quota"]
    }
}
