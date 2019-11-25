//
//  IMConvCacheObject.swift
//  merchant-ios
//
//  Created by Alan YU on 30/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class IMConvCacheObject: Object {
    
    @objc dynamic var convKey: String?
    @objc dynamic var jsonString: String?
    @objc dynamic var timestamp: Date?
    
    convenience init(conv: Conv) {
        self.init()
        self.convKey = conv.convKey
        self.timestamp = conv.timestamp as Date
        
        self.jsonString = Mapper().toJSONString(conv, prettyPrint: false)
    }
    
    override static func primaryKey() -> String? {
        return "convKey"
    }
    
    func object() -> Conv? {
        if let string = jsonString {
            let conv = Mapper<Conv>().map(JSONString: string)
            conv?.fromCache = true
            return conv
        }
        return nil
    }

}
