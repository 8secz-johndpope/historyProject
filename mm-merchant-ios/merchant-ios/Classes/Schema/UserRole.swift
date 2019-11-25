//
//  UserRole.swift
//  merchant-ios
//
//  Created by Kam on 30/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import RealmSwift
import ObjectMapper

class UserRole: Mappable {
    
    var userKey : String?
    var merchantId : Int?
    var userObj: User?
    var merchantObj: Merchant?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    convenience init(userKey: String, merchantId: Int? = nil) {
        self.init()
        self.userKey = userKey
        self.merchantId = merchantId
    }
    
    // Mappable
    func mapping(map: Map) {
        userKey <- map["UserKey"]
        merchantId <- map["MerchantId"]
    }
    
}
