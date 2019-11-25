//
//	SizeList.swift
//
//	Create by Vu Dinh Trung on 26/4/2016
//	Copyright © 2016. All rights reserved.


import Foundation
import ObjectMapper

class SizeList : Mappable{

	var sizeId : Int?
	var sizeName : String?


    required convenience init?(map: Map) {
        self.init()
    }

	func mapping(map: Map)
	{
		sizeId <- map["SizeId"]
		sizeName <- map["SizeName"]
		
	}

}
