//
//  OrderComment.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 9/5/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderComment: Mappable {
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
    }
}
