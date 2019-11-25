//
//  NewsFeedPostResult.swift
//  merchant-ios
//
//  Created by Markus Chow on 26/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

import ObjectMapper

class NewsFeedPostResult: Mappable {
	
	var postId : String!
	
	required convenience init?(map: Map) {
		self.init()
	}
	
	// Mappable
	func mapping(map: Map) {
		postId      <- map["PostId"]
		
	}
	
}
