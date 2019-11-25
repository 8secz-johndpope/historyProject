//
//  IMInitMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 9/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class IMInitMessage: IMSystemMessage {
    
    var convList = [Conv]()
    var queueList = [QueueStatistics]()
    
    override init() {
        super.init()
    }
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        convList    <- map["ConvList"]
        queueList   <- map["QueueList"]
    }
    
    func linkedCustomerServices() -> [MerchantQueues] {
        
        var result = [MerchantQueues]()
        var map = [Int: MerchantQueues]()
        
        for queue in queueList {
            
            let merchantId = queue.merchantId
            var merchant: MerchantQueues! = map[merchantId]
            
            if  merchant == nil {
                merchant = MerchantQueues(merchantId: merchantId)
                map[merchantId] = merchant
                result.append(merchant)
            }
            merchant.addQueue(queue)
            
        }
        
        return result
        
    }
    
}
