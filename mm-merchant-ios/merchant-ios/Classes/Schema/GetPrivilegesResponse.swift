//
//  GetPrivilegesResponse.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class GetPrivilegesResponse : Mappable{
    var privileges = [Privilege]()
    var loyalties = [Loyalty]()
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        privileges   <- map["Privileges"]
        loyalties    <- map["Loyalties"]
    }
}

