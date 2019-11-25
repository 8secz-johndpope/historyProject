//
//  MobileCode.swift
//  merchant-ios
//
//  Created by Hang Yuen on 6/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class MobileCode : Mappable {
    
    var mobileCodeId : Int = 0
    var mobileCodeNameInvariant : String! = ""
    var mobileCodeCultureId : Int = 0
    var cultureCode : String! = ""
    var mobileCodeName : String! = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        mobileCodeId                <- map["MobileCodeId"]
        mobileCodeNameInvariant     <- map["MobileCodeNameInvariant"]
        mobileCodeCultureId         <- map["MobileCodeNameInvariant"]
        cultureCode                 <- map["CultureCode"]
        mobileCodeName              <- map["MobileCodeName"]
    }
    
}
