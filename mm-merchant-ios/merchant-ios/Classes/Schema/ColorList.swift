//
//	ColorList.swift
//
//	Create by Vu Dinh Trung on 26/4/2016
//	Copyright © 2016. All rights reserved.


import Foundation
import ObjectMapper

class ColorList : Mappable{

	var colorCode : String?
	var colorId : Int?
	var colorImage : String?
	var colorKey : String?
	var colorName : String?
	var skuColor : String?
    
    required convenience init?(map: Map) {
        self.init()
    }
	func mapping(map: Map)
	{
		colorCode <- map["ColorCode"]
		colorId <- map["ColorId"]
		colorImage <- map["ColorImage"]
		colorKey <- map["ColorKey"]
		colorName <- map["ColorName"]
		skuColor <- map["SkuColor"]
		
	}

}
