//
//  OrderSectionData.swift
//  merchant-ios
//
//  Created by Gambogo on 4/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderSectionData: CollectionViewSectionData {
    
    var order: Order? {
        didSet {
            if let order = self.order {
                orderDisplayStatus = .unknown
                
                switch currentViewMode {
                case .all, .toBeShipped, .toBeReceived:
                    break
                case .toBeRated:
                    if let orderShipments = order.orderShipments, let filteredOrderShipmentKey = order.filteredOrderShipmentKey {
                        for orderShipment in orderShipments where orderShipment.orderShipmentKey == filteredOrderShipmentKey {
                            switch orderShipment.orderShipmentStatus {
                            case .shipped, .toShipToConsolidationCentre, .shippedToConsolidationCentre, .receivedToConsolidationCentre:
                                orderDisplayStatus = .shipped
                            case .pendingShipment:
                                orderDisplayStatus = .toBeShipped
                            case .pendingCollection:
                                orderDisplayStatus = .toBeCollected
                            case .received:
                                orderDisplayStatus = .received
                            case .collected:
                                orderDisplayStatus = .collected
                            default:
                                break
                            }
                        }
                    }
                case .afterSales:
                    if let orderReturn = order.orderReturns?.first {
                        switch orderReturn.orderReturnStatus {
                        case .returnCancelled:
                            orderDisplayStatus = .returnCancelled
                        case .returnAuthorized:
                            orderDisplayStatus = .returnRequestAuthorised
                        case .returnRequested:
                            orderDisplayStatus = .returnRequestSubmitted
                        case .returnRequestRejected:
                            orderDisplayStatus = .returnRequestRejected
                        case .returnAccepted:
                            orderDisplayStatus = .returnAccepted
                        case .returnRejected:
                            orderDisplayStatus = .returnRejected
                        case .requestDisputed:
                            orderDisplayStatus = .disputeOpen
                        case .requestDisputeInProgress:
                            orderDisplayStatus = .disputeInProgress
                        case .returnDisputed:
                            orderDisplayStatus = .disputeOpen
                        case .returnDisputeInProgress:
                            orderDisplayStatus = .disputeInProgress
                        case .disputeRejected:
                            orderDisplayStatus = .disputeRejected
                        case .disputeDeclined:
                            orderDisplayStatus = .disputeDeclined
                        case .returnRequestDeclinedCanNotDispute:
                            orderDisplayStatus = .returnRequestDeclinedCanNotDispute
                        case .returnRequestRejectedCanNotDispute:
                            orderDisplayStatus = .returnRequestRejectedCanNotDispute
                        default:
                            break
                        }
                    } else if let orderCancel = order.orderCancels?.first {
                        switch orderCancel.orderCancelStatus {
                        case .cancelAccepted:
                            orderDisplayStatus = .cancelAccepted
                        case .cancelRequested:
                            orderDisplayStatus = .cancelRequested
                        case .cancelRejected:
                            orderDisplayStatus = .cancelRejected
                        default:
                            break
                        }
                    }
                default:
                    break
                }
                
                if orderDisplayStatus == .unknown {
                    switch order.orderStatus {
                    case .initiated, .confirmed, .paid:
                        orderDisplayStatus = .toBeShipped
                    case .cancelled:
                        orderDisplayStatus = .cancelAccepted
                    case .shipped:
                        orderDisplayStatus = .shipped
                    case .partialShipped:
                        orderDisplayStatus = .partialShip
                    case .received:
                        orderDisplayStatus = .received
                    case .closed:
                        orderDisplayStatus = .orderClosed
                    case .unknown:
                        break
                    }
                }
            }
        }
    }
    
    var orderDisplayStatus: Constants.OrderDisplayStatus = .unknown
    var orderListDisplayStatus: Constants.OrderDisplayStatus = .unknown

    var orderShipment: Shipment?
    var orderItemCount: Int {
        get {
            var count = 0
            for row in self.dataSource {
                if type(of: row) == OrderItem.self {
                    count += 1
                }
            }
            return count
        }
        set {}
    }
    
    func insert(dataItem: Any, at: Int) {
        self.dataSource.insert(dataItem, at: at)
    }
    
    func append(dataItem: Any) {
        self.dataSource.append(dataItem)
    }
}
