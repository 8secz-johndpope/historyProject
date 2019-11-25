//
//  UserOrderStatus.swift
//  storefront-ios
//
//  Created by Alan YU on 4/5/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class UserOrderStatus : Mappable {
    
    required init?(map: Map) {
        
    }
    
    var isFlashSaleEligible: Bool = false
    
    // Mappable
    func mapping(map: Map) {
        isFlashSaleEligible <- map["IsFlashSaleEligible"]
    }
    
}
