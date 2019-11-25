//
//  Curatorimage.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 6/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class CuratorImage: Mappable {
    
    @objc dynamic var userImageKey = ""
    @objc dynamic var image = ""
    @objc dynamic var priority = 0
    @objc dynamic var lastModified = ""
    @objc dynamic var userImageTypeName = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        userImageKey    <- map["UserImageKey"]
        image           <- map["Image"]
        priority        <- map["Priority"]
        lastModified     <- map["LastModified"]
        userImageTypeName <- map["UserImageTypeName"]
    }
    
}
