//
//  Order.swift
//  merchant-ios
//
//  Created by Gambogo on 4/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Order: Mappable {
    
    enum OrderStatus: Int {
        case unknown = 0
        case initiated      // Not paid yet
        case confirmed      // Merchant confirmed (deduct quantity)
        case paid           // Paid
        case cancelled      // Refund
        case partialShipped
        case shipped        // To Be Received
        case received       // To Be Rated
        case closed
    }
    
    var additionalCharge: Float = 0
    var address = ""
    var city = ""
    var comments = ""
    var country = ""
    var couponAmount: Double = 0
    var couponId = 0
    var couponName: String?
    var couponReference = 0
    var cultureCode = ""
    var displayName = ""
    var district = ""
    var firstName = ""
    var freeShippingThreshold = 0
    var grandTotal: Double = 0
    var headerLogoImage = ""
    var identificationNumber = ""
    var isAliPay = false
    var isAutoConfirmOrder = false
    var isCOD = false
    var isCancelRequested = false
    var isCrossBorder = false
    var isFreeShippingOverride = false
    var isMm = false
    var isReturnRequested = false
    var isTaxInvoiceRequested = false
    var isTransactionRequested = false
    var isUserIdentificationExists = false
    var largeLogoImage = ""
    var lastClosed: Date?
    var lastConfirmed: Date?
    var lastCreated: Date?
    var lastModified: Date?
    var lastName = ""
    var lastPaid: Date?
    var lastReceived: Date?
    var lastReviewed: Date?
    var lastShipped: Date?
    var mmCouponAmount: Double = 0
    var merchantId = 0
    var merchantName = ""
    var orderCancels: [OrderCancel]?
    var orderComments: [OrderComment]?
    var orderDiscount: Double = 0
    var orderExternalCode: String?
    var orderItems: [OrderItem]?
    var orderKey = ""
    var orderReturns: [OrderReturn]?
    var orderShipments: [Shipment]?
    var orderStatusCode = ""
    var orderTransactions: [OrderTransaction]?
    var paymentTotal: Double = 0
    var phoneCode = ""
    var phoneNumber = ""
    var postalCode = ""
    var province = ""
    var recipientName = ""
    var shippingFee = 0
    var shippingTotal: Double = 0
    var smallLogoImage = ""
    var subTotal: Double = 0
    var taxInvoiceName = ""
    var taxInvoiceNumber = ""
    var userKey = ""
    var userName = ""
    
    // Deprecated
    var couponTotal: Double = 0
    var discountTotal: Double = 0
    
    // Order Status ID
    var orderStatusId = 0 // Sometimes, This will be changed after split order
    var orderStatus: OrderStatus = .unknown
    var originalOrderStatus: OrderStatus = .unknown
    var originalOrder: Order?
    var unprocessedShipment: Shipment?
    var filteredOrderShipmentKey: String?
    
    // Order ID
    var orderId = 0
    
    var map: Map?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        self.map = map
        
        additionalCharge            <- map["AdditionalCharge"]
        address                     <- map["Address"]
        city                        <- map["City"]
        comments                    <- map["Comments"]
        country                     <- map["Country"]
        couponAmount                <- map["CouponAmount"]
        couponId                    <- map["CouponId"]
        couponName                  <- map["CouponName"]
        couponReference             <- map["CouponReference"]
        cultureCode                 <- map["CultureCode"]
        displayName                 <- map["DisplayName"]
        district                    <- map["District"]
        firstName                   <- map["FirstName"]
        freeShippingThreshold       <- map["FreeShippingThreshold"]
        grandTotal                  <- map["GrandTotal"]
        headerLogoImage             <- map["HeaderLogoImage"]
        identificationNumber        <- map["IdentificationNumber"]
        isAliPay                    <- map["IsAliPay"]
        isAutoConfirmOrder          <- map["IsAutoConfirmOrder"]
        isCOD                       <- map["IsCOD"]
        isCancelRequested           <- map["IsCancelRequested"]
        isCrossBorder               <- map["IsCrossBorder"]
        isFreeShippingOverride      <- map["IsFreeShippingOverride"]
        isMm                        <- map["IsMm"]
        isReturnRequested           <- map["IsReturnRequested"]
        isTaxInvoiceRequested       <- map["IsTaxInvoiceRequested"]
        isTransactionRequested      <- map["IsTransactionRequested"]
        isUserIdentificationExists  <- map["IsUserIdentificationExists"]
        largeLogoImage              <- map["LargeLogoImage"]
        lastClosed                  <- (map["LastClosed"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastConfirmed               <- (map["LastConfirmed"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastCreated                 <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastName                    <- map["LastName"]
        lastPaid                    <- (map["LastPaid"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastReceived                <- (map["LastReceived"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastReviewed                <- (map["LastReviewed"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastShipped                 <- (map["LastShipped"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        mmCouponAmount              <- map["MMCouponAmount"]
        merchantId                  <- map["MerchantId"]
        merchantName                <- map["MerchantName"]
        orderCancels                <- map["OrderCancels"]
        orderComments               <- map["OrderComments"]
        orderDiscount               <- map["OrderDiscount"]
        orderExternalCode           <- map["OrderExternalCode"]
        orderItems                  <- map["OrderItems"]
        orderKey                    <- map["OrderKey"]
        orderReturns                <- map["OrderReturns"]
        orderShipments              <- map["OrderShipments"]
        orderStatusCode             <- map["OrderStatusCode"]
        orderTransactions           <- map["OrderTransactions"]
        paymentTotal                <- map["PaymentTotal"]
        phoneCode                   <- map["PhoneCode"]
        phoneNumber                 <- map["PhoneNumber"]
        postalCode                  <- map["PostalCode"]
        province                    <- map["Province"]
        recipientName               <- map["RecipientName"]
        shippingFee                 <- map["ShippingFee"]
        shippingTotal               <- map["ShippingTotal"]
        smallLogoImage              <- map["SmallLogoImage"]
        subTotal                    <- map["SubTotal"]
        taxInvoiceName              <- map["TaxInvoiceName"]
        taxInvoiceNumber            <- map["TaxInvoiceNumber"]
        userKey                     <- map["UserKey"]
        userName                    <- map["UserName"]
        
        // Deprecated
        couponTotal                 <- map["CouponTotal"]
        discountTotal               <- map["DiscountTotal"]
        
        orderStatusId               <- map["OrderStatusId"]
        orderStatus                 <- (map["OrderStatusId"], EnumTransform<OrderStatus>())
        originalOrderStatus         <- (map["OrderStatusId"], EnumTransform<OrderStatus>())
        
        orderId               <- map["OrderId"]
        
        
        // Get Unprocessed shipment
        
        if let orderItems = orderItems {
            var unprocessedShipmentItems = [ShipmentItem]()
            
            for orderItem in orderItems {
                let unprocessedQty = orderItem.qtyToShip + orderItem.qtyCancelled
                
                if unprocessedQty > 0 || (orderStatus == .initiated && orderItem.qtyOrdered > 0) {
                    let orderShipmentItem = ShipmentItem()
                    orderShipmentItem.skuId = orderItem.skuId
                    
                    if unprocessedQty > 0 {
                        orderShipmentItem.qtyToShip = orderItem.qtyToShip
                        orderShipmentItem.qtyCancelled = orderItem.qtyCancelled
                    } else if (orderStatus == .initiated && orderItem.qtyOrdered > 0) {
                        // Case: Order just created (From Thank you page)
                        orderShipmentItem.qtyToShip = orderItem.qtyOrdered
                    }
                    
                    unprocessedShipmentItems.append(orderShipmentItem)
                } else {
                    let orderDisplayStatus = self.orderDisplayStatus()
                    
                    switch orderDisplayStatus {
                    case .cancelAccepted, .refundAccepted:
                        let orderShipmentItem = ShipmentItem()
                        orderShipmentItem.skuId = orderItem.skuId
                        orderShipmentItem.qtyShipped = orderItem.qtyToShip
                        
                        unprocessedShipmentItems.append(orderShipmentItem)
                    default:
                        break
                    }
                }
            }
            
            if unprocessedShipmentItems.count > 0 {
                unprocessedShipment = Shipment()
                unprocessedShipment?.isProcessedShipment = false
                unprocessedShipment?.orderShipmentItems = unprocessedShipmentItems
            }
        }
        
        // Calculated qtyCancelRequested
        
        if let orderCancels = orderCancels, let orderItems = orderItems {
            let cancelRequested = orderCancels.filter{ $0.orderCancelStatus == .cancelRequested }
            
            for orderCancel in cancelRequested {
                if let cancelItem = orderCancel.orderCancelItems?.first {
                    for i in 0..<orderItems.count {
                        if orderItems[i].skuId == cancelItem.skuId {
                            orderItems[i].qtyCancelRequested += cancelItem.qtyCancelled
                            break
                        }
                    }
                }
            }
        }
        
    }
    
    func copy() -> Order {
        let order = Order()
        order.mapping(map: map!)
        
        return order
    }

    func findOrderItemBySkuId(_ skuId: Int) -> OrderItem? {
        if let orderItems = self.orderItems {
            for item in orderItems {
                if item.skuId == skuId {
                    return item
                }
            }
        }
        
        return nil
    }
    
    func orderDisplayStatus() -> Constants.OrderDisplayStatus {
        
        struct Item {
            var qtyCancelled = 0
            var qtyConfirmed = 0
            var qtyOrdered = 0
            var qtyReceived = 0
            var qtyReturnRequested = 0
            var qtyReturned = 0
            var qtyShipped = 0
            var qtyShippedPending = 0
            var qtyToShip = 0
            
            var qtyRemainForShipment = 0
        }
        
        var items: [String : Item] = [String : Item]()
        
        var totalQtyOrdered = 0
        var totalQtyCancelled = 0
        var totalQtyReturned = 0
        var totalQtyRemainForShipment = 0
        
        if let orderItems = orderItems {
            for i in 0..<orderItems.count {
                let orderItem = orderItems[i]
                let key = "\(orderItem.skuId)"
                
                if items[key] == nil {
                   items[key] = Item()
                }
                
                if items[key] != nil {
                    items[key]!.qtyCancelled += orderItem.qtyCancelled
                    items[key]!.qtyConfirmed += orderItem.qtyConfirmed
                    items[key]!.qtyOrdered += orderItem.qtyOrdered
                    items[key]!.qtyReceived += orderItem.qtyReceived
                    items[key]!.qtyReturnRequested += orderItem.qtyReturnRequested
                    items[key]!.qtyReturned += orderItem.qtyReturned
                    items[key]!.qtyShipped += orderItem.qtyShipped
                    items[key]!.qtyShippedPending += orderItem.qtyShippedPending
                    items[key]!.qtyToShip += orderItem.qtyToShip
                }
            }
            
            // Add CancelRequested qty
            if let orderCancels = orderCancels {
                for i in 0..<orderCancels.count {
                    if orderCancels[i].orderCancelStatus == .cancelRequested {
                        if let orderCancelItems = orderCancels[i].orderCancelItems {
                            for j in 0..<orderCancelItems.count {
                                let key = "\(orderCancelItems[j].skuId)"
                                items[key]!.qtyCancelled += orderCancelItems[j].qtyCancelled
                            }
                        }
                    }
                }
            }
            
            for (key, item) in items {
                // TODO: qtyReturnRequested will not be deducted after return accepted
                
                items[key]!.qtyRemainForShipment = item.qtyOrdered - item.qtyCancelled - item.qtyReturnRequested
                
                totalQtyOrdered += item.qtyOrdered
                totalQtyCancelled += item.qtyCancelled
                totalQtyReturned += item.qtyReturnRequested
                totalQtyRemainForShipment += items[key]!.qtyRemainForShipment
            }
            
            if totalQtyRemainForShipment == 0 {
                // Either cancelled all / returned all / mix
                
                if totalQtyOrdered == totalQtyCancelled {
                    if let orderCancels = orderCancels {
                        let cancelAccepted = orderCancels.filter{ $0.orderCancelStatus == .cancelAccepted }
                        let cancelRequested = orderCancels.filter{ $0.orderCancelStatus == .cancelRequested }
                        let cancelRejected = orderCancels.filter{ $0.orderCancelStatus == .cancelRejected }
                        
                        if cancelAccepted.count == orderCancels.count {
                            return .cancelAccepted
                        } else if cancelRequested.count == orderCancels.count {
                            return .cancelRequested
                        } else if cancelRejected.count == orderCancels.count {
                            return .cancelRejected
                        }
                    }
                    
                    // TODO: Mixed
                    return .unknown
                } else if totalQtyOrdered == totalQtyReturned {
                    if let orderReturns = orderReturns {
                        let returnCancelled = orderReturns.filter{ $0.orderReturnStatus == .returnCancelled }
                        let returnAuthorized = orderReturns.filter{ $0.orderReturnStatus == .returnAuthorized }
                        let returnRequested = orderReturns.filter{ $0.orderReturnStatus == .returnRequested }
                        let returnRequestRejected = orderReturns.filter{ $0.orderReturnStatus == .returnRequestRejected }
                        let returnAccepted = orderReturns.filter{ $0.orderReturnStatus == .returnAccepted }
                        let returnRejected = orderReturns.filter{ $0.orderReturnStatus == .returnRejected }
                        let requestDisputed = orderReturns.filter{ $0.orderReturnStatus == .requestDisputed }
                        let requestDisputeInProgress = orderReturns.filter{ $0.orderReturnStatus == .requestDisputeInProgress }
                        let returnDisputed = orderReturns.filter{ $0.orderReturnStatus == .returnDisputed }
                        let returnDisputeInProgress = orderReturns.filter{ $0.orderReturnStatus == .returnDisputeInProgress }
                        
                        if returnCancelled.count == orderReturns.count {
                            return .returnCancelled
                        } else if returnAuthorized.count == orderReturns.count {
                            return .returnRequestAuthorised
                        } else if returnRequested.count == orderReturns.count {
                            return .returnRequestSubmitted
                        } else if returnRequestRejected.count == orderReturns.count {
                            return .returnRequestRejected
                        } else if returnAccepted.count == orderReturns.count {
                            return .returnAccepted
                        } else if returnRejected.count == orderReturns.count {
                            return .returnRejected
                        } else if requestDisputed.count == orderReturns.count {
                            return .disputeOpen
                        } else if requestDisputeInProgress.count == orderReturns.count {
                            return .disputeInProgress
                        } else if returnDisputed.count == orderReturns.count {
                            return .disputeOpen
                        } else if returnDisputeInProgress.count == orderReturns.count {
                            return .disputeInProgress
                        }
                    }
                    
                    // TODO: Mixed
                    return .unknown
                } else {
                    // TODO: Mixed
                    return .unknown
                }
            } else {
                var noUnprocessedShipmentItem = false
                
                if let unprocessedShipment = unprocessedShipment {
                    // Has unprocessed shipment
                    
                    var totalQtyToShip = 0
                    
                    if let orderShipmentItems = unprocessedShipment.orderShipmentItems {
                        totalQtyToShip = orderShipmentItems.reduce(0){ $0 + $1.qtyToShip }
                    }
                    
                    if let orderShipments = orderShipments {
                        let filteredShipments = orderShipments.filter({ $0.orderShipmentStatus != .cancelled && $0.orderShipmentStatus != .rejected })
                        
                        if filteredShipments.count > 0 {
                            // Something shipped
                            if totalQtyToShip > 0 {
                                // Something pending shipment
                                return .partialShip
                            } else {
                                // Nothing pending shipment
                                noUnprocessedShipmentItem = false
                            }
                        } else {
                            // Nothing shipped
                            return .toBeShipped
                        }
                    } else {
                        // Nothing shipped
                        return .toBeShipped
                    }
                } else {
                    noUnprocessedShipmentItem = false
                }
                
                if !noUnprocessedShipmentItem {
                    if let orderShipments = orderShipments {
                        // All item prepared to ship
                        
                        let cancelled = orderShipments.filter{ $0.orderShipmentStatus == .cancelled }
                        
                        let shipped = orderShipments.filter{ $0.orderShipmentStatus == .shipped }
                        let pendingShipment = orderShipments.filter{ $0.orderShipmentStatus == .pendingShipment }
                        let pendingCollection = orderShipments.filter{ $0.orderShipmentStatus == .pendingCollection }
                        let received = orderShipments.filter{ $0.orderShipmentStatus == .received }
                        let collected = orderShipments.filter{ $0.orderShipmentStatus == .collected }
                        let rejected = orderShipments.filter{ $0.orderShipmentStatus == .rejected }
                        let toShipToConsolidationCentre = orderShipments.filter{ $0.orderShipmentStatus == .toShipToConsolidationCentre }
                        let shippedToConsolidationCentre = orderShipments.filter{ $0.orderShipmentStatus == .shippedToConsolidationCentre }
                        let receivedToConsolidationCentre = orderShipments.filter{ $0.orderShipmentStatus == .receivedToConsolidationCentre }
                        
                        let validShipmentCount = orderShipments.count - cancelled.count - rejected.count
                        
                        if shipped.count == validShipmentCount {
                            return .shipped
                        } else if pendingShipment.count == validShipmentCount {
                            return .toBeShipped
                        } else if pendingCollection.count == validShipmentCount {
                            return .toBeCollected
                        } else if received.count == validShipmentCount {
                            return .received
                        } else if collected.count == validShipmentCount {
                            return .collected
                        } else if toShipToConsolidationCentre.count == validShipmentCount {
                            return .shipped
                        } else if shippedToConsolidationCentre.count == validShipmentCount {
                            return .shipped
                        } else if receivedToConsolidationCentre.count == validShipmentCount {
                            return .shipped
                        }
                        
                        if validShipmentCount == 0 {
                            return .toBeShipped
                        }
                        
                        return .partialShip
                    } else {
                        // Nothing shipped (Should not happen)
                        return .unknown
                    }
                }
            }
        }
        
        return .unknown
    }
    
    func isFreeShippingEnabled() -> Bool {
        return freeShippingThreshold < Constants.MaxFreeShippingThreshold
    }
}
