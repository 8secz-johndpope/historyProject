//
//  MerchantFollowBody.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class MerchantFollowBody: Mappable {
    @objc dynamic var userKey = ""
    @objc dynamic var toMerchantId = 0
    
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        userKey      <- map["UserKey"]
        toMerchantId <- map["ToMerchantId"]
    }
}
    
