//
//  MerchantRoles.swift
//  merchant-ios
//
//  Created by Alan YU on 9/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class MerchantRoles: Mappable {
    
    var merchantId: Int?
    var roles = [Int]()
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        merchantId <- map["MerchantId"]
        roles <- map["Roles"]
    }
    
}
