//
//  UserAlias.swift
//  merchant-ios
//
//  Created by Kam on 4/11/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import ObjectMapper

class UserAlias: Mappable {
    
    var userKey : String?
    var alias : String?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    convenience init(userKey: String, alias: String?) {
        self.init()
        self.userKey = userKey
        self.alias = alias
    }
    
    // Mappable
    func mapping(map: Map) {
        userKey <- map["UserKey"]
        alias <- map["Alias"]
    }

}
