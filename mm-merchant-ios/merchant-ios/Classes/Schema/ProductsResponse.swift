//
//  ProductsResponse.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import ObjectMapper

class ProductsResponse: Mappable {
    
    var results : [Product]!
    
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        results      <- map["results"]
    }

}
