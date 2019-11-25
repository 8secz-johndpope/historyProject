//
//  LoyaltyFooter.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class LoyaltyFooter : Mappable{
    var translationCode = ""
    var url = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        translationCode   <- map["TranslationCode"]
        url               <- map["Url"]
    }
}

