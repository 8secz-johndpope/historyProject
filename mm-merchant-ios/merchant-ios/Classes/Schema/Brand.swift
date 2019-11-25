//
//  Brand.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 23/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import HandyJSON

class Brand : Mappable, Equatable, HandyJSON {
    public var vid: String = ""
    
    static func ==(lhs: Brand, rhs: Brand) -> Bool {
        return lhs.brandId == rhs.brandId
    }
    
    var brandId = 0
    var brandName = ""
    var brandNameInvariant = ""
	var brandDesc = ""
    var headerLogoImage = ""
	var smallLogoImage = ""
	var largeLogoImage = ""
	var profileBannerImage = ""
    var isSelected = false
    var brandSubdomain = ""
    var brandImages: [BrandImage]?
    var brandCode = ""
    var positionX = 0
    var positionY = 0

    var place = TagPlace.undefined

    
    var isFeaturedBrand = false
    var isListedBrand = false
    var isRed = false
    var isBlack = false
    var priority = 0
    
    var couponCount = 0
    var newStyleCount = 0
    var newSaleCount = 0
    
    var followerCount = 0
    var followStatus = true
    
    required init() {}
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
		brandId             <- map["BrandId"]
		brandName           <- map["BrandName"]
		brandNameInvariant  <- map["BrandNameInvariant"]
        brandSubdomain      <- map["BrandSubdomain"]
		brandDesc			<- map["BrandDesc"]
		headerLogoImage     <- map["HeaderLogoImage"]
		smallLogoImage		<- map["SmallLogoImage"]
		largeLogoImage		<- map["LargeLogoImage"]
		profileBannerImage	<- map["ProfileBannerImage"]
        brandImages         <- map["BrandImageList"]
        brandCode           <- map["BrandCode"]
        positionX           <- map["PositionX"]
        positionY           <- map["PositionY"]
        place               <- map["Place"]
        isFeaturedBrand     <- map["IsFeaturedBrand"]
        isListedBrand       <- map["IsListedBrand"]
        isRed               <- map["IsRed"]
        isBlack             <- map["IsBlack"]
        priority            <- map["Priority"]
        couponCount         <- map["CouponCount"]
        newStyleCount       <- map["NewStyleCount"]
        newSaleCount        <- map["NewSaleCount"]
        followerCount       <- map["FollowerCount"]
    }
    
    var BrandId: Int?
    var BrandCode: String?
    var BrandSubdomain: String?
    var BrandName: String?
    var BrandNameInvariant: String?
    var HeaderLogoImage: String?
    var SmallLogoImage: String?
    var LargeLogoImage: String?
    var ProfileBannerImage: String?
    
    
    
}
