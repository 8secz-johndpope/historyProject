//
//  Privilege.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Privilege : Mappable{
    var privilegeId = 0
    var translationCode = ""
    var iconUrl = ""
    var map: Map?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        self.map = map
        privilegeId           <- map["PrivilegeId"]
        translationCode       <- map["TranslationCode"]
        iconUrl               <- map["IconUrl"]
    }
    
    func clone() -> Privilege{
        let privilege = Privilege()
        if let map = self.map{
            privilege.mapping(map: map)
        }
        return privilege
    }
}
