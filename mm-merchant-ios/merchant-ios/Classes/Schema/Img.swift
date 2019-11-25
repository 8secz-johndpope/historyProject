//
//  ImageList.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 27/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//
import Foundation
import ObjectMapper

class Img : Mappable{
    
    var styleImageId = 0
    var imageKey = ""
    var colorKey = ""
    var position = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        imageKey                <- map["ImageKey"]
        colorKey                <- map["ColorKey"]
        styleImageId            <- map["StyleImageId"]
        position                <- map["Position"]
    }
    
}
