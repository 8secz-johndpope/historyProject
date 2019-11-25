//
//  NewsFeedListResponse.swift
//  merchant-ios
//
//  Created by Markus Chow on 26/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

import ObjectMapper

class NewsFeedListResponse: Mappable {
	
	var hitsTotal = 0
	var pageTotal = 0
	var pageSize = 0
	var pageCurrent = 0
	var pageData : [Post]?
	
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	// Mappable
	func mapping(map: Map) {
		
		hitsTotal		<- map["HitsTotal"]
		pageTotal		<- map["PageTotal"]
		pageSize		<- map["PageSize"]
		pageCurrent		<- map["PageCurrent"]
		pageData		<- map["PageData"]
		
	}
	
}
