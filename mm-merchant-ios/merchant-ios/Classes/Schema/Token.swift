//
//  Token.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class Token: Mappable {
    
    // Specify properties to ignore (Realm won't persist these)
    
    //  override static func ignoredProperties() -> [String] {
    //    return []
    //  }
    var token = ""
    var userId = 0
    var userKey = ""
    var isSignup = false
    var isActivated = false
    var isSignUp = false
//    var isMM = false

    var merchantsMap = [Int: Merchant]()
    var merchants = [Merchant]() {
        didSet {
            merchantsMap.removeAll()
            for merchant in merchants {
                merchantsMap[merchant.merchantId] = merchant
            }
        }
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        token       <- map["Token"]
        userId      <- map["UserId"]
        userKey     <- map["UserKey"]
        isSignup    <- map["IsSignup"]
        isActivated <- map["IsActivated"]
        merchants   <- map["Merchants"]
        isSignUp    <- map["IsSignUp"]
//        isMM        <- map["IsMm"]

    }
    
}
