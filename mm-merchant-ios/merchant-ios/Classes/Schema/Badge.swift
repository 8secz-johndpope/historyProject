//
//  Badge.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 15/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class Badge : Mappable, Equatable {
    
    static func ==(lhs: Badge, rhs: Badge) -> Bool {
        return lhs.badgeId == rhs.badgeId
    }

    var badgeId = 0
    var badgeName = ""
    var badgeNameInvariant = ""
    var isSelected = false
    
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        badgeId             <- map["BadgeId"]
        badgeName           <- map["BadgeName"]
        badgeNameInvariant  <- map["BadgeNameInvariant"]
    }
    
}
