//
//	FeaturedImageList.swift
//
//	Create by Vu Dinh Trung on 26/4/2016
//	Copyright © 2016. All rights reserved.


import Foundation
import ObjectMapper

class FeaturedImageList : Mappable{

	var imageKey : String?
	var position : Int?
	var styleImageId : Int?


    required convenience init?(map: Map) {
        self.init()
    }

	func mapping(map: Map)
	{
		imageKey <- map["ImageKey"]
		position <- map["Position"]
		styleImageId <- map["StyleImageId"]
		
	}

}
