//
//  KuaiDi100Data.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 19/9/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class KuaiDi100Data: Mappable {
    
    var context = ""
    var ftime = Date()
    var time = Date()
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        context                 <- map["context"]
        ftime                   <- (map["ftime"], DateTransformExtension(dateFormatString: "yyyy-MM-dd HH:mm:ss"))
        time                    <- (map["time"], DateTransformExtension(dateFormatString: "yyyy-MM-dd HH:mm:ss"))
        
    }
}
