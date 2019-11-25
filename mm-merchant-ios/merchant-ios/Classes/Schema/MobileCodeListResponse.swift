//
//  MobileCodeListResponse.swift
//  merchant-ios
//
//  Created by Hang Yuen on 6/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import ObjectMapper

class MobileCodeListResponse: Mappable {
    var results : [MobileCode]!
    
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        results      <- map["MobileCodeList"]
    }
    
}
