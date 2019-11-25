//
//  Merchant.swift
//  merchant-ios
//
//  Created by Hang Yuen on 9/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class Merchant : Mappable, Equatable {
    
    static func ==(lhs: Merchant, rhs: Merchant) -> Bool {
        return lhs.merchantId == rhs.merchantId
    }
    
    var merchantId = 0
    var merchantTypeId = 0
    var merchantName = ""
    var merchantDisplayName = ""
    var merchantCompanyName = ""
    var merchantNameInvariant = ""
    var businessRegistrationNo = ""     // API return String?
    var merchantSubdomain = ""
    var merchantDesc = ""
    var logoImage = ""
    var backgroundImage = ""
    var geoCountryId = 0
    var geoIdProvince = 0
    var geoIdCity = 0
    var district = ""
    var postalCode = ""
    var apartment = ""
    var floor = ""
    var blockNo = ""
    var building = ""
    var streetNo = ""
    var street = ""
    var statusId = 0
    var freeShippingThreshold = 0
    var freeShippingFrom: Date?
    var freeShippingTo: Date?
    var shippingFee: Double = 0
    var lastStatus = Date()
    var lastModified = Date()
    var merchantTypeName = ""
    var statusNameInvariant = ""
    var geoCountryName = ""
    var headerLogoImage = ""
    var smallLogoImage = ""
    var largeLogoImage = ""
    var profileBannerImage = ""
    var isCrossBorder = false
    var isListedMerchant = false
    private var isFeaturedMerchant = false
    var isRecommendedMerchant = false
    var isSearchableMerchant = false
    var isSelected = false
    var count = 0
    var isClicking = false
    var followerCount = 0
    var followStatus = true
    var merchantImages: [MerchantImage]?
    var positionX:CGFloat = 0
    var positionY :CGFloat = 0
    var isFollowing = false
    var merchantCode = ""
    var isLoading = false
    private var priority = 0
    
    var priorityRed = 0
    var priorityBlack = 0
    var isFeaturedRed = false
    var isFeaturedBlack = false
    
    
    lazy var MMIconCircle: UIImage = { () -> UIImage in
        return UIImage(named: "mm_white_icon")!
    } ()
    lazy var MMImageIcon: UIImage = { () -> UIImage in
        return UIImage(named: "mm_on")!
    } ()
    lazy var MMImageIconBlack: UIImage = { () -> UIImage in
        return UIImage(named: "mm_black")!
    } ()

    //custom
    var users: [User]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        merchantId              <- map["MerchantId"]
        merchantTypeId          <- map["MerchantTypeId"]
        merchantDisplayName     <- map["MerchantName"]
        merchantCompanyName     <- map["MerchantCompanyName"]
        businessRegistrationNo  <- map["BusinessRegistrationNo"]
        merchantSubdomain       <- map["MerchantSubdomain"]
        merchantDesc            <- map["MerchantDesc"]
        logoImage               <- map["LogoImage"]
        backgroundImage         <- map["ChatBackgroundImage"]
        geoCountryId            <- map["GeoCountryId"]
        geoIdProvince           <- map["GeoIdProvince"]
        geoIdCity               <- map["GeoIdCity"]
        district                <- map["District"]
        postalCode              <- map["PostalCode"]
        apartment               <- map["Apartment"]
        floor                   <- map["Floor"]
        blockNo                 <- map["BlockNo"]
        building                <- map["Building"]
        streetNo                <- map["StreetNo"]
        street                  <- map["Street"]
        statusId                <- map["StatusId"]
        shippingFee             <- map["ShippingFee"]
        freeShippingThreshold   <- map["FreeShippingThreshold"]
        freeShippingTo          <- (map["FreeShippingTo"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        freeShippingFrom        <- (map["FreeShippingFrom"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastStatus              <- (map["LastStatus"], DateTransform())
        lastModified            <- (map["LastModified"], DateTransform())
        merchantTypeName        <- map["MerchantTypeName"]
        statusNameInvariant     <- map["StatusNameInvariant"]
        geoCountryName          <- map["GeoCountryName"]
        headerLogoImage         <- map["HeaderLogoImage"]
        largeLogoImage          <- map["LargeLogoImage"]
        profileBannerImage      <- map["ProfileBannerImage"]
        isCrossBorder           <- map["IsCrossBorder"]
        isListedMerchant        <- map["IsListedMerchant"]
        isFeaturedMerchant      <- map["IsFeaturedMerchant"]
        isRecommendedMerchant   <- map["IsRecommendedMerchant"]
        isSearchableMerchant    <- map["IsSearchableMerchant"]
        merchantNameInvariant   <- map["MerchantNameInvariant"]
        merchantName            <- map["MerchantName"]
        count                   <- map["Count"]
        followerCount           <- map["FollowerCount"]
        merchantImages          <- map["MerchantImageList"]
        positionX               <- map["PositionX"]
        positionY               <- map["PositionY"]
        users                   <- map["Users"]
        merchantCode            <- map["MerchantCode"]
        smallLogoImage          <- map["SmallLogoImage"]
        priority                <- map["Priority"]
        
        priorityRed             <- map["PriorityRed"]
        priorityBlack           <- map["PriorityBlack"]
        isFeaturedRed           <- map["IsFeaturedRed"]
        isFeaturedBlack         <- map["IsFeaturedBlack"]
    }
    
    func cacheableObject() -> MerchantCacheObject {
        return MerchantCacheObject(merchant: self)
    }
    
    func isMM() -> Bool {
        return merchantId == Constants.MMMerchantId
    }
    
    func isFreeShippingEnabled() -> Bool {
        return freeShippingThreshold < Constants.MaxFreeShippingThreshold
    }
    
    static func MM() -> Merchant {
        let merchant = Merchant()
        merchant.merchantId = Constants.MMMerchantId
        merchant.merchantName = String.localize("LB_MYMM")
        merchant.merchantCompanyName = String.localize("LB_MYMM")
        merchant.merchantDisplayName = String.localize("LB_MYMM")
        return merchant
    }
    
}
