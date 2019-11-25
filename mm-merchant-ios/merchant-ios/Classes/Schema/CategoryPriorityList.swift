//
//	CategoryPriorityList.swift
//
//	Create by Vu Dinh Trung on 26/4/2016
//	Copyright © 2016. All rights reserved.


import Foundation
import ObjectMapper

class CategoryPriorityList : Mappable{

	var categoryCode : String?
	var categoryId : Int?
	var categoryImage : Any?
	var categoryName : String?
	var categoryNameInvariant : String?
	var isMerchCanSelect : Int?
	var level : Int?
	var parentCategoryId : Int?
	var priority : Int?
	var sizeGridImage : Any?
	var sizeGridImageInvariant : Any?
	var statusId : Int?

    required convenience init?(map: Map) {
        self.init()
    }
	

	func mapping(map: Map)
	{
		categoryCode <- map["CategoryCode"]
		categoryId <- map["CategoryId"]
		categoryImage <- map["CategoryImage"]
		categoryName <- map["CategoryName"]
		categoryNameInvariant <- map["CategoryNameInvariant"]
		isMerchCanSelect <- map["IsMerchCanSelect"]
		level <- map["Level"]
		parentCategoryId <- map["ParentCategoryId"]
		priority <- map["Priority"]
		sizeGridImage <- map["SizeGridImage"]
		sizeGridImageInvariant <- map["SizeGridImageInvariant"]
		statusId <- map["StatusId"]
		
	}

}
