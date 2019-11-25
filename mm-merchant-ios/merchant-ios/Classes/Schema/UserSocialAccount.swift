//
//  UserSocialAccount.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 22/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class UserSocialAccount: Mappable {
    
    var userSocialAccountTypeId = 0
    var userSocialAccountTypeName = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        userSocialAccountTypeId                 <- map["UserSocialAccountTypeId"]
        userSocialAccountTypeName               <- map["UserSocialAccountTypeName"]
        
    }
    
}
