//
//  Size.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 25/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
class Size : Mappable, Equatable {
    
    static func ==(lhs: Size, rhs: Size) -> Bool {
        return lhs.sizeId == rhs.sizeId
    }
    
    var sizeId = 0
    var sizeCode = ""
    var sizeName = ""
    var sizeGroup = ""
    var isValid = true
    var sizeGroupId = 0
    var sizeGroupName = ""
    var sizeGroupCode = ""
    var isSelected = false
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        sizeId                  <- map["SizeId"]
        sizeCode                <- map["SizeCode"]
        sizeName                <- map["SizeName"]
        sizeGroup               <- map["SizeGroup"]
        sizeGroupId             <- map["SizeGroupId"]
        sizeGroupName           <- map["SizeGroupName"]
        sizeGroupCode           <- map["SizeGroupCode"]
    }
    
}
