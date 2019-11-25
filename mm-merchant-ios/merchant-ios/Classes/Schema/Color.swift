//
//  Color.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class Color : Mappable, Equatable {
    
    static func ==(lhs: Color, rhs: Color) -> Bool {
        return lhs.colorId == lhs.colorId && lhs.colorCode == rhs.colorCode
    }
    
    var colorId = 0
    var colorName = ""
    var hexCode = ""
    var colorImage = ""
    var isValid = true
    var colorKey = ""
    var colorCode = ""
    var skuColor = ""
    var isSelected = false
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        colorId              <- map["ColorId"]
        colorName            <- map["ColorName"]
        hexCode              <- map["HexCode"]
        colorImage           <- map["ColorImage"]
        colorKey             <- map["ColorKey"]
        colorCode            <- map["ColorCode"]
        skuColor             <- map["SkuColor"]
    }

}
