//
//  Tag.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 1/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Tag : Mappable{
    var tagName = ""
    var priority = -1
    var tagTypeId = -1
    var tagTypeName = ""
    var tagId = -1
    var isSelected = false

    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        tagName              <- map["TagName"]
        priority             <- map["Priority"]
        tagTypeId            <- map["TagTypeId"]
        tagTypeName          <- map["TagTypeName"]
        tagId                <- map["TagId"]
        isSelected           <- map["IsSelected"]
    }
}
