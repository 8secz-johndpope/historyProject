//
//	Aggregation.swift
//
//	Create by Vu Dinh Trung on 26/4/2016
//	Copyright © 2016. All rights reserved.


import Foundation
import ObjectMapper


class Aggregation : NSObject, Mappable{

	var badgeArray : [Int]?
	var brandArray : [Int]?
	var categoryArray : [Int]?
	var colorArray : [Int]?
	var isNewCount : Int?
	var isSaleCount : Int?
	var merchantArray : [Int]?
	var sizeArray : [Int]?

    required convenience init?(map: Map) {
        self.init()
    }

	func mapping(map: Map)
	{
		badgeArray <- map["BadgeArray"]
		brandArray <- map["BrandArray"]
		categoryArray <- map["CategoryArray"]
		colorArray <- map["ColorArray"]
		isNewCount <- map["IsNewCount"]
		isSaleCount <- map["IsSaleCount"]
		merchantArray <- map["MerchantArray"]
		sizeArray <- map["SizeArray"]
		
	}

}
