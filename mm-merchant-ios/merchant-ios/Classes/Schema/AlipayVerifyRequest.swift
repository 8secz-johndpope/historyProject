//
//  AlipayVerifyRequest.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 10/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class AlipayVerifyRequest: Mappable {
    
    var result = ""
    
    required init?(map: Map) {
        
    }
    
    init() {
        
    }
    
    func mapping(map: Map) {
        
        result          <- map["result"]
        
    }
}
