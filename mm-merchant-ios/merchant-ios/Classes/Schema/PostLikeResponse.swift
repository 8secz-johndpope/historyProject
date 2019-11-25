//
//  PostLikeResponse.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class PostLikeResponse: Mappable {

    var hitsTotal = 0
    var pageCurrent = 0
    var likeList: [PostLike]?
    var pageSize = 0
    var pageTotal = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        hitsTotal               <- map["HitsTotal"]
        pageCurrent             <- map["PageCurrent"]
        likeList                <- map["LikeList"]
        pageSize                <- map["PageSize"]
        pageTotal               <- map["PageTotal"]
        
    }

}
