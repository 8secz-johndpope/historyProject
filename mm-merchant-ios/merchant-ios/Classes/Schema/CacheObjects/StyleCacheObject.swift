//
//  StyleCacheObject.swift
//  merchant-ios
//
//  Created by Alan YU on 1/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class StyleCacheObject: Object {
    
    @objc dynamic var styleCode: String?
    @objc dynamic var skuId: Int = -1
    @objc dynamic var jsonString: String?
    
    convenience init(skuId: Int, style: Style) {
        self.init()
        self.styleCode = style.styleCode
        self.skuId = skuId
            
        self.jsonString = Mapper().toJSONString(style, prettyPrint: false)
    }
    
    override static func primaryKey() -> String? {
        return "skuId"
    }

    func object() -> Style? {
        if let string = jsonString {
            return Mapper<Style>().map(JSONString: string)
        }
        return nil
    }
    
}
