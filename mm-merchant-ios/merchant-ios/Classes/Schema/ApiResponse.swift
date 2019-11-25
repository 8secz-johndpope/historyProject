//
//  ApiResponse.swift
//  merchant-ios
//
//  Created by Hang Yuen on 5/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

/* for handling error response
 */
class ApiResponse: Mappable {
 
    var appCode: String!
    var message: String!
    var isMobile = false

    var loginAttempts: Int!
//    var username: String!

    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        appCode         <- map["AppCode"]
        message         <- map["Message"]
        // should only on login response
        loginAttempts   <- map["LoginAttempts"]
//        username        <- map["User"]
        isMobile        <- map["IsMobile"]
    }
    
}
