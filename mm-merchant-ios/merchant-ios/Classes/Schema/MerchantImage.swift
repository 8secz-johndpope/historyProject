//
//  MerchantImage.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 3/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import RealmSwift

class MerchantImage: Mappable {
    
    var merchantImageId = 0
    var imageTypeCode = ""
    var merchantImage = ""
    var position = 0
    var link = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        merchantImageId      <- map["MerchantImageId"]
        imageTypeCode        <- map["ImageTypeCode"]
        merchantImage        <- map["MerchantImage"]
        position             <- map["Position"]
        link                 <- map["Link"]
    }
    
}
