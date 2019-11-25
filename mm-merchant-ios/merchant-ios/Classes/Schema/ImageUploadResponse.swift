//
//  ImageUploadResponse.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 28/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class ImageUploadResponse : Mappable{
    
    @objc dynamic var imageKey = ""
    @objc dynamic var imageMimeType = ""
    @objc dynamic var profileImage = ""
    @objc dynamic var coverImage = ""
    @objc dynamic var entityId = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        imageKey            <- map["ImageKey"]
        imageMimeType       <- map["ImageMimeType"]
        profileImage        <- map["ProfileImage"]
        coverImage          <- map["CoverImage"]
        entityId            <- map["EntityId"]
    }

}
