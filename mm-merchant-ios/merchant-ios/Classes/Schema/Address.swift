//
//  Address.swift
//  merchant-ios
//
//  Created by hungvo on 3/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Address : Mappable, Equatable {
    
    static func ==(lhs: Address, rhs: Address) -> Bool {
        return lhs.userAddressKey == rhs.userAddressKey
    }
    
    var userAddressKey = ""
    var recipientName = ""
    var phoneCode = ""
    var phoneNumber = ""
    var geoCountryId = 0
    var geoProvinceId = 0
    var geoCityId = 0
    var country = ""
    var province = ""
    var city = ""
    var district = ""
    var postalCode = ""
    var address = ""
    var cultureCode = ""
    var lastModified = ""
    var lastCreated = ""
    var isDefault = false

    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        userAddressKey                <- map["UserAddressKey"]
        recipientName                 <- map["RecipientName"]
        phoneCode                     <- map["PhoneCode"]
        phoneNumber                   <- map["PhoneNumber"]
        geoCountryId                  <- map["GeoCountryId"]
        geoProvinceId                 <- map["GeoProvinceId"]
        geoCityId                     <- map["GeoCityId"]
        country                       <- map["Country"]
        province                      <- map["Province"]
        city                          <- map["City"]
        district                      <- map["District"]
        postalCode                    <- map["PostalCode"]
        address                       <- map["Address"]
        cultureCode                   <- map["CultureCode"]
        lastModified                  <- map["LastModified"]
        lastCreated                   <- map["LastCreated"]
        isDefault                     <- map["IsDefault"]
    }
}
