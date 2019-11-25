//
//  BrandDetails.swift
//  merchant-ios
//
//  Created by Markus Chow on 21/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class BrandDetails : Mappable {
	
	var brandId = 0
	var brandName = ""
	var brandNameInvariant = ""
	
	var brandDesc = ""
	var headerLogoImage = ""
	var smallLogoImage = ""
	var largeLogoImage = ""
	var profileBannerImage = ""
	
	var brandImageList: [BrandImage]?
	
	var isSelected = false
	var brandSubdomain = ""
	required convenience init?(map: Map) {
		self.init()
	}
	
	// Mappable
	func mapping(map: Map) {
		
		let lang = Context.getCc().uppercased()
		let brandNameKey = "Brand.DisplayName." + lang
		let brandDescKey = "Brand.BrandDesc." + lang
		
		brandId             <- map["Brand.BrandId"]
		brandName           <- map[brandNameKey]
		brandNameInvariant  <- map["Brand.BrandNameInvariant"]
		brandSubdomain      <- map["BrandSubdomain"]
		brandDesc			<- map[brandDescKey]
		headerLogoImage     <- map["Brand.HeaderLogoImage"]
		smallLogoImage		<- map["Brand.SmallLogoImage"]
		largeLogoImage		<- map["Brand.LargeLogoImage"]
		profileBannerImage	<- map["Brand.ProfileBannerImage"]
		
		brandImageList		<- map["BrandImageList"]
		
	}
	
}
