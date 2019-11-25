//
//  InventoryLocation.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 30/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

class InventoryLocation: Mappable {
    
    var apartment = ""
    var blockNo = ""
    var building = ""
    var district = ""
    var floor = ""
    var inventoryLocationId = 0
    var merchantId = 0
    var locationExternalCode = ""
    var geoCountryId = 0
    var geoIdProvince = 0
    var geoIdCity = 0
    var inventoryLocationTypeName = ""
    var geoCountryName = ""
    var geoProvinceName = ""
    var geoCityName = ""
    var locationName = ""
    var postalCode = ""
    var streetNo = ""
    var street = ""
    
    var recipientName = ""
    var phoneCode = ""
    var phoneNumber = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        inventoryLocationId         <- map["InventoryLocationId"]
        merchantId                  <- map["MerchantId"]
        locationExternalCode        <- map["LocationExternalCode"]
        geoCountryId                <- map["GeoCountryId"]
        geoIdProvince               <- map["GeoIdProvince"]
        geoIdCity                   <- map["GeoIdCity"]
        inventoryLocationTypeName   <- map["InventoryLocationTypeName"]
        geoCountryName              <- map["GeoCountryName"]
        geoProvinceName             <- map["GeoProvinceName"]
        geoCityName                 <- map["GeoCityName"]
        locationName                <- map["LocationName"]
        district                    <- map["District"]
        apartment                   <- map["Apartment"]
        streetNo                    <- map["StreetNo"]
        street                      <- map["Street"]
        blockNo                     <- map["BlockNo"]
        building                    <- map["Building"]
        floor                       <- map["Floor"]
        postalCode                  <- map["PostalCode"]
        
        recipientName               <- map["RecipientName"]
        phoneCode                   <- map["PhoneCode"]
        phoneNumber                 <- map["PhoneNumber"]
        
    }
    
    func formatAddress() -> String {
//        if !inventoryLocation.geoCountryName.isEmptyOrNil() {
//            returnAddress += inventoryLocation.geoCountryName
//        }
        
        var resultAddress = ""
        if !self.geoProvinceName.isEmptyOrNil() {
            resultAddress += self.geoProvinceName
        }
        
        if !self.geoCityName.isEmptyOrNil() {
            resultAddress += " \(self.geoCityName)"
        }
        
        if !self.district.isEmptyOrNil() {
            resultAddress += " \(self.district)"
        }
        
        if !self.street.isEmptyOrNil() {
            resultAddress += " \(self.street)"
        }
        
        if !self.streetNo.isEmptyOrNil() {
            resultAddress += " \(self.streetNo)"
        }
        
        if !self.building.isEmptyOrNil() {
            resultAddress += " \(self.building)"
        }
        
        if !self.blockNo.isEmptyOrNil() {
            resultAddress += " \(self.blockNo)"
        }
        
        if !self.floor.isEmptyOrNil() {
            resultAddress += " \(self.floor)"
        }
        
        if !self.apartment.isEmptyOrNil() {
            resultAddress += " \(self.apartment)"
        }
        
        return resultAddress
    }
}
