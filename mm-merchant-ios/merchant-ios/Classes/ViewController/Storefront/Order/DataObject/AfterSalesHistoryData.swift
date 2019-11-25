//
//  AfterSalesHistoryData.swift
//  merchant-ios
//
//  Created by Gambogo on 4/14/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AfterSalesHistoryData {
    
    fileprivate(set) var historySubject = ""
    var historyTime = ""
    fileprivate(set) var historyDetails = ""
    fileprivate(set) var historyStatus = ""
    
    var notificationEventId: Constants.NotificationEvent = .unknown
    var orderNumber = ""
    var productName = ""
    var productQty = 0
    var courierName = ""
    var courierTrackingNumber = ""
    var shipmentNumber = ""
    var collectionNumber = ""
    var dateTimeShipmentCreated = ""
    var totalAmount = ""
    var paymentMethod = ""
    var transactionNumber = ""
    var refundNumber = ""
    var alipayAccountName = ""
    var cancelReason = ""
    var returnReason = ""
    var disputeReason = ""
    var disputeResponse = String.localize("LB_MM_DISPUTE_RESPONSE")
    
    var photoList = [String]()
    
    var order: Order? = nil {
        didSet {
            if let order = self.order {
                orderNumber = order.orderKey
                createPatternContent(self.notificationEventId)
            }
        }
    }
    
    var orderCancel: OrderCancel?
    var orderReturn: OrderReturn?
    var inventoryLocation: InventoryLocation?
    var orderReturnHistoryKey: String?
    
    init(notificationEventId: Constants.NotificationEvent = .unknown, historyTime: Date) {
        self.notificationEventId = notificationEventId
        let formatter = Constants.DateFormatter.getFormatter(DateTransformExtension.DateFormatStyle.dateOnly)
        
        if formatter.string(from: Date()) == formatter.string(from: historyTime) {
            self.historyTime = Constants.DateFormatter.getFormatter("HH:mm").string(from: historyTime)
        } else {
            self.historyTime = Constants.DateFormatter.getFormatter("yyyy-MM-dd HH:mm").string(from: historyTime)
        }
    }
    
    //MARK: - Patterns
    
    func createPatternContent(_ notificationEventId: Constants.NotificationEvent) {
        
        var result = ""
        
        historySubject = ""
        historyDetails = ""
        historyStatus = ""
        
        switch notificationEventId {
        case .unknown:
            historySubject = ""
            historyDetails = ""
            historyStatus = ""
            
        case .shipmentDeliveryShipped:
            historySubject =  String.localize("LB_CAPP_SHIPPED")
            historyStatus =  String.localize("LB_CA_SHIPMENT_TEXT")
            //TODO: Can be many product items, should check when has api
            result += "\(String.localize("LB_CA_YOUR_ORDER_1")) (\(String.localize("LB_ORDER_NO")):  \(orderNumber)) \(String.localize("LB_CA_YOUR_ORDER_2")) \(String.localize("LB_PRODUCT_NAME")): \(productName); \(String.localize("LB_QTY")):\(productQty); \n"
            result += "\(String.localize("LB_COURIER_NAME")): \(courierName);"
            result += "\( String.localize("LB_CA_OMS_SHIPMENT_NO:")): \(shipmentNumber)"
            historyDetails = result
            
        case .shipmentCollectionCreated:
            historySubject =  String.localize("LB_CAPP_TOBECOLLECTED")
            historyStatus =  ""
            //TODO: Can be many product items, should check when has api
            result += "\(String.localize("LB_CA_YOUR_ORDER_1")) (\(String.localize("LB_ORDER_NO")):  \(orderNumber)) \(String.localize("LB_CA_YOUR_ORDER_3")) \(String.localize("LB_PRODUCT_NAME")): \(productName); \(String.localize("LB_QTY")):\(productQty); \n"
            result += "\(String.localize("LB_COLLECTION_ADDRESS")): \(collectionNumber);"
            result += "\( String.localize("LB_POSTAL_OR_ZIP")): \(shipmentNumber)"
            result += "\( String.localize("LB_CS_CONTACT")): \(shipmentNumber)"
            historyDetails = result
            
        case .shipmentDeliveryCancel:
            historySubject =  String.localize("LB_SHIPMENT_CANCELLED")
            historyStatus =   String.localize("LB_SHIPMENT_CANCELLED_TEXT")
            result += "\(String.localize("LB_COURIER_NAME")): \(courierName);"
            result += "\( String.localize("LB_CA_OMS_SHIPMENT_NO:")): \(shipmentNumber)"
            historyDetails = result
        
        case .shipmentCollectionCancel:
            historySubject =  String.localize("LB_COLLECTION_CANCELLED")
            historyStatus = ""
            result += "\(String.localize("LB_COLLECTION_NO")): \(collectionNumber);"
            historyDetails = result
       
        case .shipmentCollectionCollected:
            historySubject =  String.localize("LB_COLLECTION_COLLECTED")
            historyStatus = String.localize("LB_COLLECTION_COLLECTED_TEXT")
            result += "\(String.localize("LB_COLLECTION_NO")): \(collectionNumber);"
            historyDetails = result
        
        case .shipmentDeliveryNotCollected:
            historySubject =  String.localize("LB_CAPP_RECEIVING_REMINDER")
            historyStatus = ""
            result += "\(String.localize("LB_COURIER_NAME")): \(courierName);\n"
            result += "\(String.localize("LB_CA_OMS_SHIPMENT_NO")): \(courierTrackingNumber);\n"
            result += "\(String.localize("LB_CAPP_RECEIVING_REMINDER_TEXT1"))\(dateTimeShipmentCreated)\(String.localize("LB_CAPP_RECEIVING_REMINDER_TEXT2"))"
            historyDetails = result
            
        case .shipmentAutoReceived:
            historySubject = String.localize("LB_SHIPMENT_AUTORECEIVE")
            historyStatus = String.localize("LB_CA_SHIPMENT_AUTORECEIVE_TEXT")
            result += "\(String.localize("LB_COURIER_NAME")): \(courierName);\n"
            result += "\(String.localize("LB_CA_OMS_SHIPMENT_NO")): \(courierTrackingNumber);"
            historyDetails = result
            
        case .orderAlipaySuccess:
            historySubject = String.localize("LB_ALIPAY_SUCCESS")
            historyStatus = ""
            result += "\(String.localize("LB_CA_YOUR_ORDER_8")) (\(String.localize("LB_ORDER_NO")): \(orderNumber))) \n"
            result += "\(String.localize("LB_AMOUNT")): \(totalAmount)\(String.localize("LB_YUAN"))\n"
            result += "\(String.localize("LB_PAYMENT_METHOD")): \(paymentMethod);\n"
            result += "\(String.localize("LB_CA_ALIPAY_SUCCESS_TEXT"))\n"
            result += "\(String.localize("LB_CA_OMS_ORDER_DETAIL_TRANSACTION_NUM")): \(transactionNumber)"
            historyDetails = result
            
        case .orderAlipayFailed:
            historySubject = String.localize("LB_ALIPAY_FAIL")
            historyStatus = String.localize("LB_CA_ALIPAY_FAIL_TEXT")
            result += "(\(String.localize("LB_ORDER_NO")): \(orderNumber))\(String.localize("LB_CA_YOUR_ORDER_9"))\n\n"
            result += "\(String.localize("LB_AMOUNT")): \(totalAmount)\(String.localize("LB_YUAN"))\n"
            result += "\(String.localize("LB_PAYMENT_METHOD")): \(paymentMethod);\n"
            historyDetails = result
            
        case .orderCODPaymentCreated:
            historySubject = String.localize("LB_COD_SUCCESS")
            historyStatus = String.localize("LB_CA_ALIPAY_FAIL_TEXT")
            result += "\(String.localize("LB_CA_YOUR_ORDER_10")) (\(String.localize("LB_ORDER_NO")): \(orderNumber)) (\(String.localize("LB_AMOUNT")) \(totalAmount) \(String.localize("LB_YUAN"))"
            historyDetails = result
            
        case .orderRefundSuccess:
            historySubject = String.localize("LB_ALIPAY_RETURN_SUCCESS")
            historyStatus = "\(String.localize("LB_REFUND_NO")): \(refundNumber)"
            result += "\(String.localize("LB_AMOUNT")): \(totalAmount) \(String.localize("LB_YUAN"))\n"
            result += "\(String.localize("LB_ACC_NAME")): \(alipayAccountName)\n\n"
            result += String.localize("LB_CA_ALIPAY_RETURN_SUCCESS_TEXT")
            historyDetails = result
            
        case .orderDetailUpdated:
            historySubject = String.localize("LB_ORDER_INFO_UPDATED")
            historyStatus = String.localize("LB_ORDER_INFO_UPDATED_TEXT")
            result += "\(String.localize("LB_CA_YOUR_ORDER_4")) (\(String.localize("LB_ORDER_NO")): \(orderNumber)) \(String.localize("LB_CA_YOUR_ORDER_5"))\n\n"
            historyDetails = result
        
        //-- Order Cancel
        case .orderConsumerRequestCancel, .orderItemsCancelByMerchants, .orderItemsCancelAccepted, .orderItemsCancelRejected:
            var productNameAndPriceSentence = ""
            var description = ""
            
            if let order = self.order {
                if let orderItems = order.orderItems, let orderCancelItems = orderCancel?.orderCancelItems {
                    for orderCancelItem in orderCancelItems {
                        for orderItem in orderItems {
                            if orderItem.skuId == orderCancelItem.skuId {
                                productNameAndPriceSentence += "\(String.localize("LB_PRODUCT_NAME")): \(orderItem.skuName)\n"
                                
                                if !orderItem.colorName.isEmpty && orderItem.colorId != 1 { //ColorId = 1 mean empty
                                    productNameAndPriceSentence += "\(String.localize("LB_CA_COLOUR")): \(orderItem.colorName)\n"
                                }
                                
                                if !orderItem.sizeName.isEmpty && orderItem.sizeId != 1 { //SizeId = 1 means empty
                                    productNameAndPriceSentence += "\(String.localize("LB_CA_SIZE")): \(orderItem.sizeName)\n"
                                }
                                
                                productNameAndPriceSentence += "\(String.localize("LB_CA_QUANTITY")): \(orderCancelItem.qtyCancelled)\n\n"
                            }
                        }
                    }
                }
                
                if let orderCancel = orderCancel {
                    description = orderCancel.description
                }
            }
            
            switch notificationEventId {
            case .orderConsumerRequestCancel:
                // API Ready
                historySubject = String.localize("LB_CANCEL_REQUESTED")
                
                historyDetails += String.localize("MSG_CANCEL_CREATED") + "\n\n"
                historyDetails += productNameAndPriceSentence
                historyDetails += String.localize("LB_CANCEL_REASON") + ": \(cancelReason)\n\n"
                
                if description.length > 0 {
                    historyDetails += description + "\n"
                }
            case .orderItemsCancelByMerchants, .orderItemsCancelAccepted:
                // API Ready
                historySubject = String.localize("LB_CANCEL_ORDER")
                
                historyDetails += "\(String.localize("LB_CA_YOUR_ORDER_1"))\(String.localize("LB_CA_YOUR_ORDER_13"))\n\n"
                historyDetails += productNameAndPriceSentence
                historyDetails += "\n" + String.localize("LB_CANCEL_ORDER_TEXT") + "\n"
                let orderPushText = String.localize("LB_CA_ORDER_PUSH").replacingOccurrences(of: "{Order Number}", with: (self.order?.orderKey ?? ""))
                historyDetails += "\n" + orderPushText + "\n"
                
            case .orderItemsCancelRejected:
                // API Ready
                historySubject = String.localize("LB_CA_CANCEL_REJECTED")
                
                historyDetails += "\(String.localize("LB_CA_YOUR_ORDER_1"))\(String.localize("LB_CA_YOUR_ORDER_12"))\n\n"
                historyDetails += productNameAndPriceSentence
                historyDetails += "\n" + String.localize("LB_CA_CANCEL_REJECTED") + "\n"
                let orderPushText = String.localize("LB_CA_ORDER_PUSH").replacingOccurrences(of: "{Order Number}", with: (self.order?.orderKey ?? ""))
                historyDetails += "\n" + orderPushText + "\n"
            default:
                break
            }
            
        //-- Order Return (Include dispute)
        case .returnRequested, .returnAuthorized, .returnRequestRejected, .returnConsumerNotFilledReturn, .returnConsumerCancelRequest, .returnAccepted, .returnRejected, .disputeSubmitted, .disputeProgress, .disputeApproved, .disputeDeclined, .disputeRejected, .returnRequestDeclinedCanNotDispute, .returnRequestRejectedCanNotDispute:
            var productNameAndPriceSentence = ""
            var description = ""
            
            if let order = self.order {
                if let orderItems = order.orderItems, let orderReturnItems = orderReturn?.orderReturnItems {
                    for orderReturnItem in orderReturnItems {
                        for orderItem in orderItems {
                            if orderItem.skuId == orderReturnItem.skuId {
                                var orderPrice = ""
                                
                                if let amount = orderReturn?.amount {
                                    if let price = amount.formatPrice(currencySymbol: "") {
                                        orderPrice = price.trim()
                                    } else {
                                        orderPrice = "\(amount)"
                                    }
                                }
                                
                                productNameAndPriceSentence += "\(String.localize("LB_PRODUCT_NAME")): \(orderItem.skuName)\n"
                                
                                if !orderItem.colorName.isEmpty && orderItem.colorId != 1 { //Color Id = 1 means empty
                                    productNameAndPriceSentence += "\(String.localize("LB_CA_COLOUR")): \(orderItem.colorName)\n"
                                }
                                
                                if !orderItem.sizeName.isEmpty && orderItem.sizeId != 1 { //SizeId = 1 means empty
                                    productNameAndPriceSentence += "\(String.localize("LB_CA_SIZE")): \(orderItem.sizeName)\n"
                                }
                                
                                productNameAndPriceSentence += "\(String.localize("LB_CA_QUANTITY")): \(orderReturnItem.qtyReturned)\n"
                                productNameAndPriceSentence += "\(String.localize("LB_AMOUNT")): \(orderPrice)\(String.localize("LB_YUAN"))\n\n"
                            }
                        }
                    }
                }
                
                if let orderReturn = orderReturn {
                    if let orderReturnHistoryKey = orderReturnHistoryKey, let orderReturnHistories = orderReturn.orderReturnHistories {
                        for orderReturnHistory in orderReturnHistories where orderReturnHistory.orderReturnHistoryKey == orderReturnHistoryKey {
                            description = orderReturnHistory.description
                            break
                        }
                    }
                    
                    historyStatus = "\(String.localize("LB_RMA_NO")): \(orderReturn.orderReturnKey)"
                }
            }
            
            switch notificationEventId {
            case .returnRequested:
                historySubject = String.localize("LB_CAPP_RETURN_REQUEST")
                
                historyDetails += String.localize("LB_CA_RMA_TEXT_1") + "\n\n"
                historyDetails += productNameAndPriceSentence
                historyDetails += "\(String.localize("LB_RETURN_REASON")): \(returnReason)\n"
                historyDetails += String.localize("LB_CA_RETURN_REQUEST_TEXT") + "\n\n"
                
                if description.length > 0 {
                    historyDetails += description + "\n"
                }
            case .returnAuthorized:
                historySubject = String.localize("LB_CA_RETURN_AUTHORISED")
               
                historyDetails += String.localize("LB_CA_RMA_TEXT_2") + "\n\n"
                historyDetails += self.getReturnAddress()
                historyDetails += String.localize("LB_CA_RETURN_AUTHORISED_TEXT") + "\n"
            case .returnRequestRejected:
                historySubject = String.localize("LB_CA_RETURN_REJECTED")
                
                historyDetails += "\(String.localize("LB_RETURN_REASON")): \(returnReason)\n\n"
                historyDetails += String.localize("LB_CA_RETURN_REJECTED_TEXT") + "\n"
            case .returnConsumerNotFilledReturn:
                historySubject = String.localize("LB_CAPP_RETURN_REMINDER")
                
                historyDetails += String.localize("LB_CA_RETURN_REMINDER_TEXT") + "\n"
            case .returnConsumerCancelRequest:
                historySubject = String.localize("LB_CAPP_RETURN_CANCEL")
                
                historyDetails += String.localize("LB_CA_RETURN_CANCEL_TEXT") + "\n"
            case .returnAccepted:
                historySubject = String.localize("LB_RETURN_ACCEPT")
            case .returnRejected:
                historySubject = String.localize("LB_RETURN_REJECT")
                
                historyDetails += String.localize("LB_CA_RETURN_REJECTED_TEXT") + "\n"
            case .disputeSubmitted:
                historySubject = String.localize("LB_CAPP_DISPUTE_REQUEST")
                
                historyDetails += String.localize("LB_CA_RMA_TEXT_1") + "\n\n"
                historyDetails += productNameAndPriceSentence
                historyDetails += "\(String.localize("LB_DISPUTE_REASON")): \(disputeReason)\n\n"
                
                if description.length > 0 {
                    historyDetails += description + "\n\n"
                }
                
                historyDetails += String.localize("LB_CA_DISPUTE_REQUEST_TEXT") + "\n"
            case .disputeProgress:
                historySubject = String.localize("LB_CA_DISPUTE_INPROGRESS")
                
                historyDetails = String.localize("LB_CA_DISPUTE_INPROGRESS_TEXT") + "\n"
            case .disputeApproved:
                historySubject = String.localize("LB_CAPP_DISPUTE_CONSUMER_SUCCESS")
                
                historyDetails = "\(String.localize("LB_MM_DISPUTE_RESPONSE"))\n"
            case .disputeDeclined:
                historySubject = String.localize("LB_CAPP_DISPUTE_CONSUMER_FAIL")
                
                historyDetails = "\(String.localize("LB_MM_DISPUTE_RESPONSE_DELINED"))\n"
            case .disputeRejected:
                historySubject = String.localize("LB_CAPP_DISPUTE_CANCEL")
                
                historyDetails = "\(String.localize("LB_CA_RMA_TEXT_2"))\n"
            default:
                break
            }
        }
    }
    
    func getReturnAddress() -> String {
        var returnAddress = "\(String.localize("LB_RTN_ADDR")): "
        
        if let inventoryLocation = self.inventoryLocation {
            if !inventoryLocation.geoCountryName.isEmptyOrNil() {
                returnAddress += inventoryLocation.geoCountryName + " "
            }
            
            returnAddress += inventoryLocation.formatAddress()
            
            if !returnAddress.isEmptyOrNil() {
                returnAddress += "\n"
            }
            
            if !inventoryLocation.recipientName.isEmptyOrNil() {
                returnAddress += "\(String.localize("LB_RECEIPIENT")): "
                returnAddress += inventoryLocation.recipientName + "\n"
            }
            
            if !inventoryLocation.phoneNumber.isEmptyOrNil() {
                returnAddress += "\(String.localize("LB_CONTACT")): "
                returnAddress += inventoryLocation.phoneCode + inventoryLocation.phoneNumber + "\n"
            }
            
            if !returnAddress.isEmptyOrNil() {
                returnAddress += "\n"
            }
            
            if !inventoryLocation.postalCode.isEmptyOrNil() {
                returnAddress += "\(String.localize("LB_CA_POSTAL_CODE")): \(inventoryLocation.postalCode)\n\n"
            }
        }
        
        return returnAddress
    }
}
