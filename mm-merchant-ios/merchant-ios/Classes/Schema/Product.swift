//
//  Product.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 22/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import RealmSwift
import ObjectMapper

class Product: Mappable {
    
    var color = [""]
    var size = [0]
    var price : Double = 0
    var originalPrice : Double = 0
    var descript = ""
    var id = ""
    var name = ""
    var brand = ""
    var coverPhoto = ""
    var categoryId = 0
    var like = false
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        color                   <- map["color"]
        price                   <- map["price"]
        originalPrice           <- map["originalPrice"]
        descript                <- map["description"]
        id                      <- map["objectId"]
        name                    <- map["name"]
        brand                   <- map["brand"]
        size                    <- map["size"]
        coverPhoto              <- map["coverPhoto"]
        categoryId              <- map["categoryId"]
    }

}
