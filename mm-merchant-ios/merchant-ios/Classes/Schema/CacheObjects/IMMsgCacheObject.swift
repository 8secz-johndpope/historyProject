//
//  IMMsgCacheObject.swift
//  merchant-ios
//
//  Created by Alan YU on 30/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper

class IMMsgCacheObject: Object {
    
    @objc dynamic var msgKey: String?
    @objc dynamic var correlationKey: String?
    @objc dynamic var convKey: String?
    @objc dynamic var jsonString: String?
    @objc dynamic var timestamp: Date?
    
    convenience init(message: ChatModel) {
        self.init()
        
        self.msgKey = message.messageId
        self.convKey = message.convKey
        self.timestamp = message.timeDate as Date
        self.correlationKey = message.correlationKey
        
        self.jsonString = Mapper().toJSONString(message, prettyPrint: false)
    }
    
    override static func primaryKey() -> String? {
        return "correlationKey"
    }
    
    func object() -> ChatModel? {
        if let string = jsonString {
            let model = Mapper<ChatModel>().map(JSONString: string)
            model?.fromCacahe = true
            return model
        }
        return nil
    }

}
