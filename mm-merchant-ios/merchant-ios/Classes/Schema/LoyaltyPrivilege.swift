//
//  LoyaltyPrivilege.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/5/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

import Foundation
import ObjectMapper

class LoyaltyPrivilege : Mappable{
    var privilegeId = 0
    var privilegePageUrl = ""
    
    //custom
    var privilege: Privilege?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        privilegeId           <- map["PrivilegeId"]
        privilegePageUrl      <- map["PrivilegePageUrl"]
    }
}
