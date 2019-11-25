//
//  BrandUnionMerchant.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 31/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import HandyJSON

class BrandUnionMerchant : Mappable, DBModel {
    var ssn_rowid: Int64 = 0
    
    var entityId = 0
    var entity = ""
    var name = ""
    var nameInvariant = ""
    var description = ""
    var isListed = false
    var isFeatured = false
    var isRecommended = false
    var headerLogoImage = ""
    var smallLogoImage = ""
    var largeLogoImage = ""
    var profileBannerImage = ""
    var entityCode = ""
    var merchantCode: String?{
        get {
            if entity == "Merchant"{
                return entityCode
            }
            return nil
        }
        set {
            
        }
    }
    var brandCode: String?{
        get {
            if entity == "Brand"{
                return entityCode
            }
            return nil
        }
        set {
            
        }
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    required init() {}
    
    // Mappable
    func mapping(map: Map) {
        entityId            <- map["EntityId"]
        entity              <- map["Entity"]
        name                <- map["Name"]
        nameInvariant       <- map["NameInvariant"]
        description         <- map["Description"]
        isListed            <- map["IsListed"]
        isFeatured          <- map["IsFeatured"]
        isRecommended       <- map["IsRecommended"]
        headerLogoImage     <- map["HeaderLogoImage"]
        smallLogoImage      <- map["SmallLogoImage"]
        largeLogoImage      <- map["LargeLogoImage"]
        profileBannerImage  <- map["ProfileBannerImage"]
        entityCode          <- map["EntityCode"]
    }

    fileprivate(set) var imageCategory: ImageCategory {
        get {
            var category: ImageCategory  = .merchant
            if entity == "Brand" {
                category = .brand
            }
            return category
        }
        set {
            
        }
    }
    
}
