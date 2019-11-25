//
//  HashTag.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class HashTag: Mappable {
    var featuredTagId = 0
    var featuredTagTypeCode = ""
    var tag = ""
    var badgeCode = ""
    var priority = 0
    var lastCreated = ""
    var placeHolder = ""
    
    //custom
    var defaultValue = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    convenience init(name: String, placeHolderString: String? = nil) {
        self.init()
        self.tag = name
        self.placeHolder = placeHolderString ?? ""
    }
    
    func getHashTag() -> String {
        if self.tag.hasPrefix("#") {
            return self.tag
        }else {
            return "#" + self.tag
        }
    }
    
    // Mappable
    func mapping(map: Map) {
        featuredTagId           <- map["FeaturedTagId"]
        featuredTagTypeCode     <- map["FeaturedTagTypeCode"]
        tag                     <- map["Tag"]
        badgeCode               <- map["BadgeCode"]
        priority                <- map["Priority"]
        lastCreated             <- map["LastCreated"]
        
    }
}
