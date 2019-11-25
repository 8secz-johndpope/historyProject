//
//  Coupon.swift
//  merchant-ios
//
//  Created by Jerry Chong on 7/26/17.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class StyleCoupon: Mappable {
    var styleId = 0
    var statusId = 0
    var elasticScore: Double = 0
    var couponList = [Coupon]()

    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        styleId                       <- map["StyleId"]
        statusId                      <- map["StatusId"]
        couponList                    <- map["CouponList"]
        elasticScore                  <- map["ElasticScore"]

    }
    
    func couponCount() -> Int {
        return couponList.count
    }
}
