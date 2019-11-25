//
//  MagazineCover.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class MagazineCover: Mappable {
    
    var category = ""
    var contentPageName = ""
    var contentPageKey = ""
    var contentPageId = 0
    var coverImage = ""
    var isLike: Bool = false
    var contentPageTypeId = 0  // 1:静态界面 2:magazine界面 3:cms界面
    var contentPageCollectionId = 0
    var contentPageCollectionName = ""
    var likeCount = 0
    var lastCreated = Date()
    var lastModified = Date()
    var total = 0
    var link = ""
    
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        contentPageName             <- map["ContentPageName"]
        contentPageKey              <- map["ContentPageKey"]
        contentPageId               <- map["ContentPageId"]
        coverImage                  <- map["CoverImage"]
        contentPageTypeId           <- map["ContentPageTypeId"]
        contentPageCollectionId     <- map["ContentPageCollectionId"]
        contentPageCollectionName   <- map["ContentPageCollectionName"]
        likeCount                   <- map["LikeCount"]
        lastCreated                 <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        total                       <- map["Total"]
        link                        <- map["Link"]
        isLike                      <- map["IsSelfLiked"]
    }
}
