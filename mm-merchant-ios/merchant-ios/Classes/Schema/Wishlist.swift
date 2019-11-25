//
//  Wishlist.swift
//  merchant-ios
//
//  Created by HungPM on 1/22/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Wishlist : Mappable {
    var cartKey = ""
    var userKey = ""
    var cartTypeId = 0
    var statusId = 0
    var cartItems : [CartItem]?
    var lastCreated = ""
    var lastModified = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        cartKey               <- map["CartKey"]
        cartItems             <- map["CartItems"]
        userKey               <- map["UserKey"]
        cartTypeId            <- map["CartTypeId"]
        statusId              <- map["StatusId"]
        lastCreated           <- map["LastCreated"]
        lastModified          <- map["LastModified"]
    }
}
