//
//  IMMsgListResponseMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 27/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMMsgListResponseMessage: IMSystemMessage {
    
    var messageList = [ChatModel]()
    
    override init() {
        super.init()
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        messageList    <- map["MsgList"]
    }
    
    func cacheableObjects() -> [IMMsgCacheObject] {
        var cacheList = [IMMsgCacheObject]()
        for message in messageList {
            cacheList.append(IMMsgCacheObject(message: message))
        }
        return cacheList
    }
}
