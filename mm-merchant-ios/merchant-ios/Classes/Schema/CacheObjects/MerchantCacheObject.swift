//
//  MerchantCacheObject.swift
//  merchant-ios
//
//  Created by Alan YU on 1/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class MerchantCacheObject: Object {
    
    @objc dynamic var merchantId: Int = -1
    @objc dynamic var jsonString: String?
    
    convenience init(merchant: Merchant) {
        self.init()
        self.merchantId = merchant.merchantId
        
        self.jsonString = Mapper().toJSONString(merchant, prettyPrint: false)
    }
    
    override static func primaryKey() -> String? {
        return "merchantId"
    }
    
    func object() -> Merchant? {
        if let string = jsonString {
            return Mapper<Merchant>().map(JSONString: string)
        }
        return nil
    }
    
}
