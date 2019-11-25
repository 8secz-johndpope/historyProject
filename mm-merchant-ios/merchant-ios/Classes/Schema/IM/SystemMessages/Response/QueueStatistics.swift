//
//  QueueStatistics.swift
//  merchant-ios
//
//  Created by Alan YU on 9/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

enum QueueType: String {
    case Unknown = "Unknown"
    case Presales = "Presales"
    case Postsales = "Postsales"
    case General = "General"
    case Escalation = "Escalation"
    case Business = "Business"
}

class QueueStatistics: IMSystemMessage {
    
    var convType = ConvType.Unknown
    var merchantId: Int = -1
    var queue = QueueType.Unknown
    
    // New means the call is from a customer and its unanswered by any agent
    var new = 0
    
    // Agent Means we are waiting on an Agent to Reply
    var agent = 0
    
    // Customer means we are waiting on a Customer to reply
    var customer = 0
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        convType    <-  (map["ConvType"], EnumTransform())
        merchantId  <-  map["MerchantId"]
        queue       <-  (map["Queue"], EnumTransform())
        new         <-  map["New"]
        agent       <-  map["Agent"]
        customer    <-  map["Customer"]
    }
    
    func isMM() -> Bool {
        return merchantId == 0
    }
    
    class func queueText(_ queue: QueueType) -> String {
        var retText = ""
        switch queue {
        case .Presales:
            retText = String.localize("LB_CS_QUEUE_PRE_SALE")
        case .Postsales:
            retText = String.localize("LB_CS_QUEUE_POST_SALE")
        case .General:
            retText = String.localize("LB_CS_QUEUE_GENERAL")
        case .Escalation:
            retText = String.localize("LB_CS_QUEUE_ESCAL")
        case .Business:
            retText = String.localize("LB_CS_QUEUE_BUSINESS")
        default:break
        }

        return retText
    }
}
