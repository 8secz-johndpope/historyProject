//
//  PopupCoupon.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/30.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper

class PopupCoupon: Mappable {
    public var hitsTotal:Int = 0
    public var pageSize:Int = 0
    public var pageCurrent:Int = 0
    public var pageTotal:Int = 0
    public var pageSuper:Bool = false
    public var pageData:[Coupon]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        hitsTotal       <- map["HitsTotal"]
        pageSize       <- map["PageSize"]
        pageCurrent       <- map["PageCurrent"]
        pageTotal       <- map["PageTotal"]
        pageSuper       <- map["PageSuper"]
        pageData       <- map["PageData"]
    }
    

}
