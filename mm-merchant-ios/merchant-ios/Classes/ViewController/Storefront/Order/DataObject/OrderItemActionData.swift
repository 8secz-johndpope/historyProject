//
//  OrderItemActionData.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/19/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderItemActionData {
    
    var orderItem: OrderItem?
    var order: Order?
    var actionButtonType: OrderItemActionCell.ActionButtonType = .unknown
    var actionStatus: OrderItemActionCell.ActionStatus = .unknown
    var numOfProcessingQty = 0
    var numOfQtyAvailable = 0
    var afterSalesKey: String? // orderCancelKey / orderReturnKey
    
    init(order: Order? = nil, orderItem: OrderItem? = nil, actionButtonType: OrderItemActionCell.ActionButtonType = .unknown, actionStatus: OrderItemActionCell.ActionStatus = .unknown, numOfProcessingQty: Int? = nil, numOfQtyAvailable: Int? = nil, afterSalesKey: String? = nil) {
        self.order = order
        self.orderItem = orderItem
        self.actionButtonType = actionButtonType
        self.actionStatus = actionStatus
        self.afterSalesKey = afterSalesKey
        
        if let numOfProcessingQty = numOfProcessingQty {
            self.numOfProcessingQty = numOfProcessingQty
        }
        
        if let numOfQtyAvailable = numOfQtyAvailable {
            self.numOfQtyAvailable = numOfQtyAvailable
        }
    }
    
}
