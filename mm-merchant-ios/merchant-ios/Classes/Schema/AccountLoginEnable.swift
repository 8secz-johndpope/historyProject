//
//  AccountLoginEnable.swift
//  storefront-ios
//
//  Created by Kam on 19/7/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class AccountLoginEnable: Mappable {
    var enable: Bool = false
    var appVersion: String = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        enable      <- map["enable"]
        appVersion  <- map["appVersion"]
    }
}
