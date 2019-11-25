//
//  Aggregations.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 6/1/2016.
//  Copyright © 2016 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
class Aggregations : Mappable{
    
    var categoryArray : [Int] = []
    var brandArray : [Int] = []
    var merchantArray : [Int] = []
    var sizeArray : [Int] = []
    var colorArray : [Int] = []
    var badgeArray : [Int] = []
    var isSaleCount = 0
    var isNewCount = 0
    var map: Map?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        self.map = map
        categoryArray               <- map["CategoryArray"]
        brandArray                  <- map["BrandArray"]
        merchantArray               <- map["MerchantArray"]
        sizeArray                   <- map["SizeArray"]
        colorArray                  <- map["ColorArray"]
        badgeArray                  <- map["BadgeArray"]
        isSaleCount                 <- map["IsSaleCount"]
        isNewCount                  <- map["IsNewCount"]
    }
    
    func clone() -> Aggregations{
        let aggregations = Aggregations()
        if let map = self.map{
            aggregations.mapping(map: map)
        }
        return aggregations
    }
}
