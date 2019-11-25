//
//  MobileVerification.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class MobileVerification : Mappable{
    var mobileVerificationId = 0
    var mobileVerificationToken = ""
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        mobileVerificationId              <- map["MobileVerificationId"]
        mobileVerificationToken           <- map["MobileVerificationToken"]
        
    }
}
