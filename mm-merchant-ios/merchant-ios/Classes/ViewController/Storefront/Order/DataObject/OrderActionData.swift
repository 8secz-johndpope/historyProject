//
//  OrderActionData.swift
//  merchant-ios
//
//  Created by Gambogo on 4/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderActionData {
    
    var orderStatus: Order.OrderStatus = .unknown
    var orderDisplayStatus: Constants.OrderDisplayStatus = .unknown
    var courierUrl = ""
    var orderShipmentNumber = ""
    var orderShipmentKey = ""
    var orderShipmentStatus: Shipment.OrderShipmentStatus = .unknown
    var order: Order?
	var isReviewSubmitted = false
    var orderShipmentToBeReceivedCount = 0
    var orderShipmentToBeRatedCount = 0
    
    init(order: Order, orderDisplayStatus: Constants.OrderDisplayStatus = .unknown) {
        self.order = order
        self.orderStatus = order.orderStatus
        self.orderDisplayStatus = orderDisplayStatus
        
        if let orderShipments = order.orderShipments {
            for i in 0..<orderShipments.count {
                if orderShipments[i].orderShipmentStatus != .cancelled {
                    courierUrl = orderShipments[i].courierUrl
                    orderShipmentNumber = orderShipments[i].orderShipmentNumber
                    orderShipmentKey = orderShipments[i].orderShipmentKey
                    orderShipmentStatus = orderShipments[i].orderShipmentStatus
                    isReviewSubmitted = orderShipments[i].isReviewSubmitted
                    
                    break
                }
            }
            
            for orderShipment in orderShipments {
                switch orderShipment.orderShipmentStatus {
                case .shipped, .toShipToConsolidationCentre, .shippedToConsolidationCentre, .receivedToConsolidationCentre:
                    orderShipmentToBeReceivedCount += 1
                case .received, .collected:
                    orderShipmentToBeRatedCount += 1
                default:
                    break
                }
            }
        }
    }
    
}
