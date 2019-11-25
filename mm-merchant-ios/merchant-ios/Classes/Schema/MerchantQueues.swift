//
//  MerchantQueues.swift
//  merchant-ios
//
//  Created by Alan YU on 9/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class MerchantQueues {
    
    var merchantId: Int
    
    private var queues = [QueueType: [ConvType: QueueStatistics]]()
    
    init(merchantId: Int) {
        self.merchantId = merchantId;
    }
    
    func addQueue(_ queue: QueueStatistics) {
        
        if queues[queue.queue] == nil {
            queues[queue.queue] = [ConvType: QueueStatistics]()
        }
        
        queues[queue.queue]![queue.convType] = queue
        
    }
    
    func queueByType(_ queueType: QueueType, convType: ConvType) -> QueueStatistics? {
        return queues[queueType]?[convType]
    }
    
}
