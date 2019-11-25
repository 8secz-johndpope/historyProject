//
//  OrderManager.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 7/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class OrderManager {
    
    static let PhotoSize = CGSize(width: 500, height: 500)
    static let ToBeShipDays = 3
    static let DomesticArriveDays = 7
    static let CrossBorderArriveDays = 14
    
    enum SplitType: Int {
        case shipment
        case cancel
        case `return`
    }
    
    class func splitOrder(_ order: Order) -> [Order] {
        var orders = [Order]()
        
        // Split order shipment
        // Cancel order item will be handled in "order.orderCancels"
        if order.orderStatus != .cancelled {
            if let shipmentOrders: [Order] = OrderManager.splitOrderList(originalOrder: order, splitType: .shipment) {
                orders.append(contentsOf: shipmentOrders)
            } else {
                // To Remove items not belong to "To Be Shipped" Order
                if order.orderStatus == .confirmed || order.orderStatus == .paid {
                    let filterOrder = order.copy()
                    filterOrder.originalOrder = order.copy()
                    
                    if let orderItems = filterOrder.orderItems {
                        if let filteredOrderItems = removeItemsNotInToBeShippedOrder(orderItems) {
                            let sumItemAmount = filteredOrderItems.reduce(Double(0), {$0 + $1.itemTotal})
                            filterOrder.subTotal = sumItemAmount
                            filterOrder.orderItems = filteredOrderItems
                            orders.append(filterOrder)
                        }
                    }
                } else {
                    orders.append(order)
                }
            }
        }
        
        // Split order cancel
        if let orderCancels: [Order] = OrderManager.splitOrderList(originalOrder: order, splitType: .cancel) {
            orders.append(contentsOf: orderCancels)
        }
        
        // Split order return
        if let orderReturns: [Order] = OrderManager.splitOrderList(originalOrder: order, splitType: .return) {
            orders.append(contentsOf: orderReturns)
        }
        
        return orders
    }
    
    // To remove items not relate to "To Be Shipped" order
    // This function to subtract Cancel/Return/Disputes out of items
    // Return nil if removed all items for Cancel/Return/Dispute
    class func removeItemsNotInToBeShippedOrder(_ orderItems: [OrderItem]?) -> [OrderItem]? {
        var results = [OrderItem]()
        if let orderItems = orderItems {
            for orderItem in orderItems {
                
                orderItem.qtyOrdered -= orderItem.qtyCancelled
                orderItem.qtyCancelled = 0
                
                if orderItem.qtyOrdered > 0 {
                    orderItem.itemTotal = orderItem.unitPrice * Double(orderItem.qtyOrdered)
                    results.append(orderItem)
                }
            }
        }
        
        if results.count > 0 {
            return results
        }
        
        return nil
    }
    
    class func splitOrderList(originalOrder order: Order, splitType: SplitType) -> [Order]? {
        switch splitType {
        case .shipment:
            return splitShipmentOrderList(order)
        case .cancel:
            return splitOrderCancelList(order)
        case .return:
            return splitOrderReturnList(order)
        }
    }
    
    class func buildOrderSectionData(withOrder order: Order, viewMode: Constants.OmsViewMode = .unknown) -> OrderSectionData {
        
        
        let data = OrderSectionData(sectionHeader: [], reuseIdentifier: OrderItemCell.CellIdentifier, dataSource: order.orderItems ?? [], viewMode: viewMode)
        data.order = order
        
        if let orderShipments = order.orderShipments, orderShipments.count > 0 {
            data.orderShipment = orderShipments.first
            
            if viewMode == .toBeRated {
                if let orderItems = order.orderItems, let orderShipment = data.orderShipment, let orderShipmentItems = orderShipment.orderShipmentItems {
                    var filteredOrderItems = [OrderItem]()
                    
                    for orderItem in orderItems {
                        if orderShipmentItems.filter({ $0.skuId == orderItem.skuId }).count > 0 {
                            filteredOrderItems.append(orderItem)
                        }
                    }
                    
                    data.dataSource = filteredOrderItems
                }
            }
        }
        
        let orderStatusData = OrderStatusData(order: order, orderDisplayStatus: data.orderDisplayStatus)
        data.insert(dataItem: orderStatusData, at: 0) // Insert to data source at index 0
        
        let orderActionData = OrderActionData(order: order, orderDisplayStatus: data.orderDisplayStatus)
        data.append(dataItem: orderActionData) // Append to data source
        
        return data
    }
    
    class func buildUnpaidOrderSectionData(withOrder unpaidOrder: ParentOrder) -> SectionUnpaidOrderCellData {
        var datasources = [UnpaidOrderCellData]()
        if let merchants = unpaidOrder.orders {
            for merchant in merchants {
                //merchant
                let sectionDataMerchant = UnpaidOrderCellData(type: .merchant, content: merchant)
                datasources.append(sectionDataMerchant)
                if let items = merchant.orderItems {
                    for item in items {
                        //item
                        let sectionDataItem = UnpaidOrderCellData(type: .item, content: item)
                         datasources.append(sectionDataItem)
                    }
                }
            }
        }
        
        let sectionAction = UnpaidOrderCellData(type: .action, content: unpaidOrder)
        datasources.append(sectionAction)

        let sectionData = SectionUnpaidOrderCellData()
        sectionData.datasource = datasources
        return sectionData
    }
    
    class func buildUnpaidDetailOrderSectionData(withOrder unpaidOrder: ParentOrder) -> [SectionUnpaidOrderCellData] {
        var sectionDatas = [SectionUnpaidOrderCellData]()
        
        // <-Address->
        let addressSection = SectionUnpaidOrderCellData()
        if let merchants = unpaidOrder.orders {
            if (merchants.count > 0){
                let addressRow = UnpaidOrderCellData(type: .deliveryAddress, content: merchants[0])
                addressSection.datasource = [addressRow]
            }
        }
        sectionDatas.append(addressSection) // input data
        
        
        //  <-Sub-order per merchant->
        if let merchants = unpaidOrder.orders {
            for merchant in merchants {
                let orderSection = SectionUnpaidOrderCellData()
                var orderDataSources = [UnpaidOrderCellData]()
                
                let merchantData = UnpaidOrderCellData(type: .merchant, content: merchant)
                merchantData.parentOrder = unpaidOrder
                merchantData.merchantId = merchant.merchantId
                orderDataSources.append(merchantData)        // <== Merchant
                let merchantId = merchant.merchantId
                if let items = merchant.orderItems {
                    for item in items {
                        let itemData = UnpaidOrderCellData(type: .item, content: item)
                        itemData.merchantId = merchantId
                        orderDataSources.append(itemData)        // <==== Item
                    }
                }
                orderDataSources.append(UnpaidOrderCellData(type: .invoice, content: merchant))         // <- Invoice
                orderDataSources.append(UnpaidOrderCellData(type: .shipping, content: merchant))        // <- Shipping Fee
                orderDataSources.append(UnpaidOrderCellData(type: .merchantCoupon, content: merchant))  // <- Merchant Coupon
                orderDataSources.append(UnpaidOrderCellData(type: .subtotal, content: merchant))        // <- Subtotal
                orderDataSources.append(UnpaidOrderCellData(type: .comments, content: merchant))        // <- Comments
                
                orderSection.datasource = orderDataSources
                sectionDatas.append(orderSection)
            }
        }
        
        // <-MMcoupon->
        let mmCouponSection = SectionUnpaidOrderCellData()
        let mmCouponRow = UnpaidOrderCellData(type: .mmCoupon, content: unpaidOrder)
        mmCouponSection.datasource = [mmCouponRow]
        sectionDatas.append(mmCouponSection)
        
        // <-Alipay->
        let alipaySection = SectionUnpaidOrderCellData()
        let alipayRow = UnpaidOrderCellData(type: .alipyIcon, content: unpaidOrder)
        alipaySection.datasource = [alipayRow]
        sectionDatas.append(alipaySection)

        return sectionDatas
    }
    
    class func normalizedOrderImage(_ image: UIImage) -> UIImage{
        let image = image.normalizedImage()
        let size = ChatConfig.getSendImageSize(image.size, inboundSize: OrderManager.PhotoSize)
        
        guard let resizedImage = image.resize(size) else {
            return image
        }
        
        return resizedImage
    }
    
    class func orderDisplayStatus(orderReturn: OrderReturn) -> Constants.OrderDisplayStatus{
        switch orderReturn.orderReturnStatus {
        case .returnCancelled:
            return .returnCancelled
        case .returnAuthorized:
            return .returnRequestAuthorised
        case .returnRequested:
            return .returnRequestSubmitted
        case .returnRequestRejected:
            return .returnRequestRejected
        case .returnAccepted:
            return .returnAccepted
        case .returnRejected:
            return .returnRejected
        case .requestDisputed:
            return .disputeOpen
        case .requestDisputeInProgress:
            return .disputeInProgress
        case .returnDisputed:
            return .disputeOpen
        case .returnDisputeInProgress:
            return .disputeInProgress
        case .disputeDeclined:
            return .disputeDeclined
        case .disputeRejected:
            return .disputeRejected
        case .returnRequestDeclinedCanNotDispute:
            return .returnRequestDeclinedCanNotDispute
        case .returnRequestRejectedCanNotDispute:
            return .returnRequestRejectedCanNotDispute
        default:
            break
        }
        return .unknown
    }
    //MARK: - Private Class Function
    
    //! Split Original order by shipment item and also the remaining order items after split by shipment
    private class func splitShipmentOrderList(_ order: Order) -> [Order]? {
        
        var results = [Order]()
        let orderItems = order.orderItems
        let orderShipments = order.orderShipments
        var remainingOrderItems: [String: OrderItem] = [String: OrderItem]()
        
        // ------------- SPLIT ORDER BY SHIPMENT
        if orderItems != nil && orderShipments != nil && orderShipments?.count > 0 {
            for orderItem in orderItems! {
                remainingOrderItems["\(orderItem.skuId)"] = orderItem
            }
            
            for orderShipment in orderShipments! {
                
                // Handle Shipped / PendingShipment / PendingCollection / Received / Collected only
                // It will not be displayed in any view mode
                
                switch orderShipment.orderShipmentStatus {
                case .shipped, .pendingShipment, .pendingCollection, .received, .collected, .toShipToConsolidationCentre, .shippedToConsolidationCentre, .receivedToConsolidationCentre:
                    let splitedOrder = order.copy()
                    splitedOrder.originalOrder = order.copy()
                    splitedOrder.orderShipments = [orderShipment]   // One Shipment only
                    splitedOrder.orderCancels = nil
                    splitedOrder.orderReturns = nil
                    
                    if splitedOrder.orderShipments != nil && splitedOrder.orderShipments?.count > 0 {
                        if let orderShipmentItems = splitedOrder.orderShipments![0].orderShipmentItems {
                            var subTotal: Double = 0
                            var groupedOrderShipmentItems = [String : ShipmentItem]()
                            
                            for orderShipmentItem in orderShipmentItems {
                                groupedOrderShipmentItems["\(orderShipmentItem.skuId)"] = orderShipmentItem
                            }
                            
                            if splitedOrder.orderItems != nil {
                                for orderItem in splitedOrder.orderItems! {
                                    let key = "\(orderItem.skuId)"
                                    
                                    if groupedOrderShipmentItems[key] != nil {
                                        // Record found in shipment item, update
                                        let qtyShipped = (groupedOrderShipmentItems[key]?.qtyShipped)!
                                        orderItem.qtyOrdered = qtyShipped
                                        orderItem.qtyShipped = qtyShipped
                                        
                                        if (remainingOrderItems[key]?.qtyOrdered > 0) {
                                            subTotal += orderItem.unitPrice * Double(qtyShipped)
                                            
                                            // Deduct from remaining order item
                                            remainingOrderItems[key]?.qtyOrdered -= qtyShipped
                                        }
                                    } else {
                                        // Record not found in shipment item, delete it
                                        orderItem.qtyOrdered = 0
                                    }
                                }
                                
                                if splitedOrder.orderItems != nil {
                                    for i in (0..<splitedOrder.orderItems!.count).reversed() {
                                        if splitedOrder.orderItems![i].qtyOrdered == 0 {
                                            splitedOrder.orderItems!.remove(at: i)
                                        }
                                    }
                                }
                            }
                            
                            if splitedOrder.orderStatus == .partialShipped {
                                // Update orderStatus after splited
                                switch orderShipment.orderShipmentStatus {
                                case .shipped:
                                    splitedOrder.orderStatus = .shipped
                                case .pendingShipment:
                                    splitedOrder.orderStatus = .confirmed
                                case .pendingCollection:
                                    splitedOrder.orderStatus = .shipped
                                case .received, .collected:
                                    splitedOrder.orderStatus = .received
                                default:
                                    break
                                }
                            }
                            
                            // Update total
                            splitedOrder.subTotal = subTotal
                        }
                    }
                    
                    results.append(splitedOrder)
                default:
                    break
                }
            }
            
            // Handle remaining orders (Do not have shipment status)
            let orderItemToBeShipped = orderItems?.filter({ (orderItem) -> Bool in
                return orderItem.qtyToShip > 0
            })
            
            if orderItemToBeShipped != nil && orderItemToBeShipped!.count > 0 {
                // To Remove items not belong to "To Be Shipped" Order
                if let filteredOrderItems = removeItemsNotInToBeShippedOrder(orderItemToBeShipped) {
                    let splitedOrder = order.copy()
                    splitedOrder.originalOrder = order.copy()
                    splitedOrder.orderShipments?.removeAll()
                    splitedOrder.orderStatus = .confirmed
                    splitedOrder.orderItems = filteredOrderItems
                    splitedOrder.subTotal = filteredOrderItems.reduce(0, {$0 + $1.itemTotal})
                    
                    if results.count > 0 {
                        results.insert(splitedOrder, at: 0)
                    } else {
                        results.append(splitedOrder)
                    }
                    
                }
            }
        }
        
        if results.count <= 0 {
            return nil
        }
        
        return results
    }
    
    private class func splitOrderCancelList(_ order: Order) -> [Order]? {
        var results = [Order]()
        let orderItems = order.orderItems
        let orderCancels = order.orderCancels
        
        if orderItems != nil && orderCancels != nil && orderCancels?.count > 0 {
            for orderCancel in orderCancels! {
                let splitedOrder = order.copy()
                splitedOrder.originalOrder = order.copy()
                splitedOrder.orderShipments = nil
                splitedOrder.orderCancels = [orderCancel]   // One Cancel only
                splitedOrder.orderReturns = nil
              
                if let orderCancelItems = orderCancel.orderCancelItems {
                    var subTotal: Double = 0
                    var groupedOrderCancelItems = [String : OrderCancelItem]()
                    
                    for orderCancelItem in orderCancelItems {
                        groupedOrderCancelItems["\(orderCancelItem.skuId)"] = orderCancelItem
                    }
                    
                    if splitedOrder.orderItems != nil {
                        for orderItem in splitedOrder.orderItems! {
                            let key = "\(orderItem.skuId)"
                            
                            if groupedOrderCancelItems[key] != nil {
                                // Record found in shipment item, update
                                let qtyCancelled = (groupedOrderCancelItems[key]?.qtyCancelled)!
                                orderItem.qtyCancelled = qtyCancelled
                                
                                subTotal += orderItem.unitPrice * Double(qtyCancelled)
                            } else {
                                orderItem.qtyCancelled = 0
                            }
                        }
                        
                        if splitedOrder.orderItems != nil {
                            for i in (0..<splitedOrder.orderItems!.count).reversed() {
                                if splitedOrder.orderItems![i].qtyCancelled == 0 {
                                    splitedOrder.orderItems!.remove(at: i)

                                }
                            }
                        }
                    }
                    
                    // Update total
                    splitedOrder.subTotal = subTotal
                    splitedOrder.orderStatus = .cancelled // For displaying item in Tab Refund
                    
                    // Make sure order has orderItems
                    if splitedOrder.orderItems?.count > 0 {
                        results.append(splitedOrder)
                    }
                }
            }
        }
        
        return results
    }
    
    private class func splitOrderReturnList(_ order: Order) -> [Order]? {
        var results = [Order]()
        let orderItems = order.orderItems
        let orderReturns = order.orderReturns
        
        if orderItems != nil && orderReturns != nil && orderReturns?.count > 0 {
            
            for orderReturn in orderReturns! {
                // Ignore OrderReturnStatus == Cancelled
                // It will not be displayed in any view mode
                if orderReturn.orderReturnStatus == .returnCancelled {
                    continue
                }
                
                let splitedOrder = order.copy()
                splitedOrder.originalOrder = order.copy()
                splitedOrder.orderCancels = nil
                splitedOrder.orderReturns = [orderReturn]
             
                if let orderReturnItems = orderReturn.orderReturnItems {
                    var subTotal: Double = 0
                    var groupedOrderReturnItems = [String : OrderReturnItem]()
                    
                    var foundShipmentReturn = false
                    for orderReturnItem in orderReturnItems {
                        groupedOrderReturnItems["\(orderReturnItem.skuId)"] = orderReturnItem
                        
                        // Find order shipment belong to order return
                        // Current logic for filtering order return shipment is: find first skuId in order return map to first skuId in order Shipment and get only 1 shipment for return
                        if !foundShipmentReturn {
                            if let orderShipments = splitedOrder.orderShipments {
                                var shipmentReturn: Shipment? = nil
                                for shipment in orderShipments {
                                    if let orderShipmentItems = shipment.orderShipmentItems {
                                        let isContainsInOrderReturn = orderShipmentItems.contains(where: { (shipmentItem) -> Bool in
                                            return shipmentItem.skuId == orderReturnItem.skuId
                                        })
                                        
                                        if isContainsInOrderReturn {
                                            foundShipmentReturn = true
                                            shipmentReturn = shipment
                                            break
                                        }
                                    }
                                }
                                
                                if shipmentReturn != nil {
                                    splitedOrder.orderShipments = [shipmentReturn!]
                                }
                            }
                        }
                    }
                    
                    if splitedOrder.orderItems != nil {
                        for orderItem in splitedOrder.orderItems! {
                            let key = "\(orderItem.skuId)"
                            
                            if groupedOrderReturnItems[key] != nil {
                                // Record found in shipment item, update
                                let qtyReturned = (groupedOrderReturnItems[key]?.qtyReturned)!
                                orderItem.qtyReturned = qtyReturned
                                
                                subTotal += orderItem.unitPrice * Double(qtyReturned)
                            } else {
                                orderItem.qtyReturned = 0
                            }
                        }
                        
                        if splitedOrder.orderItems != nil {
                            for i in (0..<splitedOrder.orderItems!.count).reversed() {
                                if splitedOrder.orderItems![i].qtyReturned == 0 {
                                    splitedOrder.orderItems!.remove(at: i)
                                }
                            }
                        }
                    }
                    
                    // Update total
                    splitedOrder.subTotal = subTotal
                    splitedOrder.orderStatus = .cancelled // For displaying item in Tab Refund
                    
                    // Make sure order has orderItems
                    if splitedOrder.orderItems?.count > 0 {
                        results.append(splitedOrder)
                    }
                }
            }
        }
        
        if results.count == 0 {
            return nil
        }
        
        return results
    }
    
}
