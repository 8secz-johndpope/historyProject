//
//  GeoCountry.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class GeoCountry : Mappable{
    var geoCountryId = 0
    var countryCode = ""
    var geoCountryNameInvariant = ""
    var mobileCode = ""
    var geoCountryName = ""
    var isSelected = false
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        geoCountryId            <- map["GeoCountryId"]
        countryCode             <- map["CountryCode"]
        geoCountryNameInvariant <- map["GeoCountryNameInvariant"]
        mobileCode              <- map["MobileCode"]
        geoCountryName          <- map["GeoCountryName"]
        
    }
}
