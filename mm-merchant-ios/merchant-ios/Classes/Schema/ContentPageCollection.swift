//
//  ContentPageCollection.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class ContentPageCollection : Mappable {
    
    var contentPageCollectionId = 0
    var contentPageCollectionName = ""
    var coverImage = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        contentPageCollectionId             <- map["ContentPageCollectionId"]
        contentPageCollectionName           <- map["ContentPageCollectionName"]
        coverImage                          <- map["CoverImage"]
    }
    
}
