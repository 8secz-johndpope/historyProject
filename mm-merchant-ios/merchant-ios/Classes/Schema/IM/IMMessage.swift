//
//  IMMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 4/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import RealmSwift

class IMMessage: Mappable {
    
    var type = MessageType.Message
    var senderUserKey: String!
    var msgSenderMerchantId: Int?
    var timestamp = Date()
    var correlationKey: String = Utils.UUID()
    
    var readyToSend = true
    var includeSenderMerchantId = true
    
    init() {
        
    }
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    func mapping(map: Map) {
        type                <-  (map["Type"], EnumTransform())
        senderUserKey       <-  map["SenderUserKey"]
        timestamp           <-  (map["Timestamp"], IMDateTransform())
        correlationKey      <-  map["CorrelationKey"]
        
        if includeSenderMerchantId {
            msgSenderMerchantId <- map["SenderMerchantId"]
        }
    }
    
    func JSONString() -> String? {
        return convertObjectToJSONString(self.JSONObject())
    }
    
    func JSONObject() -> [String: Any] {
        
        var json: [String: Any] = [
            "Type":             type.rawValue,
            "SenderUserKey":    senderUserKey,
            "CorrelationKey":   correlationKey
        ]
        
        if let timestampStr = DateTransformExtension().convertToJSON(self.timestamp) {
            json["Timestamp"] = timestampStr
        }
        
        if includeSenderMerchantId {
            json["SenderMerchantId"] = JSONOptionalValue(msgSenderMerchantId)
        }
        
        return json
    }
    
    func convertObjectToJSONString(_ JSONDict: [String: Any], prettyPrint: Bool = false) -> String? {
        if JSONSerialization.isValidJSONObject(JSONDict) {
            let options: JSONSerialization.WritingOptions = prettyPrint ? .prettyPrinted : []
            let JSONData: Data?
            do {
                JSONData = try JSONSerialization.data(withJSONObject: JSONDict, options: options)
            } catch let error {
                print(error)
                JSONData = nil
            }
            
            if let JSON = JSONData {
                return String(data: JSON, encoding: String.Encoding.utf8)
            }
        }
        return nil
    }
    
    func prepare(completion: ((_ message: IMMessage) -> Void)? = nil, failure: (() -> Void)? = nil) {
        
    }
    
    func toChatModel() -> ChatModel? {
        return nil
    }
    
    func cacheableObject() -> Object? {
        return nil
    }
    
    func cacheableObjects() -> [Object] {
        return []
    }
    
}
