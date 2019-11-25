//
//  ReviewReportReason.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/13/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class ReviewReportReason: BaseReason {
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    override func mapping(map: Map) {
        super.mapping(map: map)
    }
    
}
