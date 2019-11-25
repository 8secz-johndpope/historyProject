//
//  GeoCity.swift
//  merchant-ios
//
//  Created by hungvo on 3/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class GeoCity : Mappable{
    var geoId = 0
    var geoNameInvariant = ""
    var geoName = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        geoId                     <- map["GeoId"]
        geoNameInvariant          <- map["GeoNameInvariant"]
        geoName                   <- map["GeoName"]
        
    }
}
