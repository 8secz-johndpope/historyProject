//
//  Size.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 25/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
class Mapping : Mappable{
    var colorId = 0
    var badgeId = 0
    var isFemale = false
    var isMale = false
    var autoSort = false
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        colorId                 <- map["ColorId"]
        badgeId                 <- map["BadgeId"]
        isFemale                <- map["IsFemale"]
        isMale                  <- map["IsMale"]
        autoSort                <- map["AutoSort"]
    }
    
}
