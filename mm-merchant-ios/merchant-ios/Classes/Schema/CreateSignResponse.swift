//
//  CreateSignResponse.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 10/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class CreateSignResponse: Mappable {
    
    var paymentString = ""
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        
        paymentString           <- map["paymentString"]
        
    }
}
