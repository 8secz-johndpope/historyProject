//
//  OrderShipStatusData.swift
//  merchant-ios
//
//  Created by Gambogo on 4/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderStatusData {
    
    var orderStatus: Order.OrderStatus = .unknown
    var orderDisplayStatus: Constants.OrderDisplayStatus = .unknown
    var orderShipmentStatus: Shipment.OrderShipmentStatus = .unknown
    var orderDate = ""
    var estimatedDaysOfCompletion = 0
    
    struct OrderStatusDisplayInfo {
        var imageName = ""
        var text = ""
    }
    
    init(order: Order, orderDisplayStatus: Constants.OrderDisplayStatus = .unknown) {
        self.orderStatus = order.orderStatus
        self.orderDisplayStatus = orderDisplayStatus
        
        if let lastCreated: Date = order.lastCreated as Date? {
            orderDate = "\(lastCreated.year)" + String.localize("LB_CA_YEAR") + "\(lastCreated.month)" + String.localize("LB_CA_MONTH") + "\(lastCreated.day)" + String.localize("LB_CA_DAY")
        }
        
        estimatedDaysOfCompletion = OrderManager.ToBeShipDays
        
        if let orderShipments = order.orderShipments, orderShipments.count > 0 {
            if let orderShipment = orderShipments.first {
                orderShipmentStatus = orderShipment.orderShipmentStatus
            } else {
                orderShipmentStatus = .unknown
            }
        }
    }
    
    func getOrderStatusDisplayInfo(showInOrderList: Bool) -> OrderStatusDisplayInfo {
        var orderStatusDisplayInfo = OrderStatusDisplayInfo()
        
        switch orderDisplayStatus {
        case .toBeShipped:
            orderStatusDisplayInfo.imageName = "icon_order_waitingShipped"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_TO_BE_SHIPPED")
            switch orderShipmentStatus{
            case .toShipToConsolidationCentre:
                orderStatusDisplayInfo.imageName = "icon_order_waitingShipped"
                orderStatusDisplayInfo.text = String.localize("LB_PENDING_SHIP_TO_CC")
            default:
                break
            }
        case .partialShip:
            orderStatusDisplayInfo.imageName = "icon_order_shipped"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_PARTIAL_SHIPPED")
        case .shipped:
            orderStatusDisplayInfo.imageName = "icon_order_shipped"
            
            switch orderShipmentStatus {
            case .shippedToConsolidationCentre, .receivedToConsolidationCentre:
                orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_CC")
            default:
                orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_SHIPPED")
            }
        case .received, .collected:
            orderStatusDisplayInfo.imageName = "icon_order_confirmed"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_RECEIVE")
        case .toBeCollected:
            orderStatusDisplayInfo.imageName = "icon_order_collection"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_TOBECOLLECTED")
        case .cancelRequested:
            orderStatusDisplayInfo.imageName = "icon_order_cancel"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_CANCEL_REQUESTED")
        case .cancelAccepted:
            orderStatusDisplayInfo.imageName = "icon_order_cancel"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_CANCEL_ACCEPTED")
        case .cancelRejected:
            orderStatusDisplayInfo.imageName = "icon_order_cancel"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_CANCEL_REJECTED")
        case .refundAccepted:
            orderStatusDisplayInfo.imageName = "icon_order_cancel"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_REFUND")
        case .returnRequestSubmitted:
            orderStatusDisplayInfo.imageName = "icon_order_return"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_RTN_REQUESTED")
        case .returnRequestAuthorised:
            orderStatusDisplayInfo.imageName = "icon_order_return"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_RTN_AUTH")
        case .returnRequestRejected:
            orderStatusDisplayInfo.imageName = "icon_order_return"
            orderStatusDisplayInfo.text = String.localize("LB_REJECT_REQUEST")
        case .returnAccepted:
            orderStatusDisplayInfo.imageName = "icon_order_return"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_RTN_ACCEPT")
        case .returnRejected:
            orderStatusDisplayInfo.imageName = "icon_order_return"
            orderStatusDisplayInfo.text = String.localize("LB_RETURN_REJECT")
        case .disputeOpen:
            orderStatusDisplayInfo.imageName = "icon_order_dispute"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_DISPUTE_REQ")
        case .disputeInProgress:
            orderStatusDisplayInfo.imageName = "icon_order_dispute"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_DISPUTE_PROCESS")
        case .disputeAccepted:
            orderStatusDisplayInfo.imageName = "icon_order_dispute"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_DISPUTE_SUCCESS")
        case .disputeRejected:
            orderStatusDisplayInfo.imageName = "icon_order_dispute"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_DISPUTE_FAIL")
        case .returnRequestDeclinedCanNotDispute:
            orderStatusDisplayInfo.imageName = "icon_order_return"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_RETURN_REQUEST_DECLINED_CANNOT_DISPUTE")
        case .returnRequestRejectedCanNotDispute:
            orderStatusDisplayInfo.imageName = "icon_order_return"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_RETURN_REJECTED_CANNOT_DISPUTE")
        case .orderClosed:
            orderStatusDisplayInfo.imageName = "icon_order_closed"
            orderStatusDisplayInfo.text = String.localize("LB_CA_OMS_ORDER_STATUS_CLOSED")
        default:
            break
        }
        
        return orderStatusDisplayInfo
    }
    
}
