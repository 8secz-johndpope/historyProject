//
//  BrandImage.swift
//  merchant-ios
//
//  Created by Markus Chow on 19/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class BrandImage: Mappable {
	
	@objc dynamic var brandImageId = 0
	@objc dynamic var brandId = 0
	@objc dynamic var imageTypeCode = ""
	@objc dynamic var brandImage = ""
	@objc dynamic var position = 0
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	// Mappable
	func mapping(map: Map) {
		brandImageId		<- map["BrandImageId"]
		brandId				<- map["BrandId"]
		imageTypeCode       <- map["ImageTypeCode"]
		brandImage			<- map["BrandImage"]
		position            <- map["Position"]
	}
}

