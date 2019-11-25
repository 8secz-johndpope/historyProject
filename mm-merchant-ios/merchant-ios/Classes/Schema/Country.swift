//
//  Country.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 16/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class Country: Mappable {
    
    @objc dynamic var name = ""
    @objc dynamic var callingCodes = [""]

    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        name            <- map["name"]
        callingCodes    <- map["callingCodes"]

    }
}
