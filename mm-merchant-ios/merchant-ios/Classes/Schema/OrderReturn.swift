//
//  OrderReturn.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 20/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderReturn: Mappable {
    
    enum OrderReturnStatus: Int {
        case unknown = 0
        case returnCancelled
        case returnAuthorized
        case returnRequested
        case returnRequestRejected
        case returnAccepted
        case returnRejected
        case requestDisputed
        case requestDisputeInProgress
        case returnDisputed
        case returnDisputeInProgress
        case disputeDeclined
        case disputeRejected
        case returnRequestDeclinedCanNotDispute
        case returnRequestRejectedCanNotDispute
    }
    
    var amount: Float = 0
    var comments = ""
    var consignmentNumber = ""
    var couponAdjustmentAmount: Float = 0
    var courierCode = ""
    var courierId = 0
    var description = ""
    var displayName = ""
    var firstName = ""
    var image1 = ""
    var image2 = ""
    var image3 = ""
    var inventoryLocationId = 0
    var isFreeShippingOverride = 0
    var isMm = 0
    var isRefundRequested = 0
    var isTaxInvoiceBack = 0
    var itemAmount: Float = 0
    var lastCreated: Date?
    var lastModified: Date?
    var lastName = ""
    var locationExternalCode = ""
    var logoImage = ""
    var merchantId: Int?
    var mmCouponAdjustmentAmount: Float = 0
    var order: Order?
    var orderDiscountAdjustmentAmount: Float = 0
    var orderDisputeReasonId = 0
    var orderReturnConditionId = 0
    var orderReturnHistories: [OrderReturnHistory]?
    var orderReturnItems: [OrderReturnItem]?
    var orderReturnKey = ""
    var orderReturnReasonId = 0
    var orderReturnResponseId = 0
    var orderReturnStatusCode = ""
    var orderReturnStatusId = 0
    var orderTransactionKey = ""
    var shippingAdjustmentAmount: Float = 0
    var userKey = ""
    var userName = ""
    
    var orderReturnStatus: OrderReturnStatus = .unknown
    var orderReturnSubmitCount = 0
    var orderDisputeSubmitCount = 0
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        amount                          <- map["Amount"]
        comments                        <- map["Comments"]
        consignmentNumber               <- map["ConsignmentNumber"]
        couponAdjustmentAmount          <- map["CouponAdjustmentAmount"]
        courierCode                     <- map["CourierCode"]
        courierId                       <- map["CourierId"]
        description                     <- map["Description"]
        displayName                     <- map["DisplayName"]
        firstName                       <- map["FirstName"]
        image1                          <- map["Image1"]
        image2                          <- map["Image2"]
        image3                          <- map["Image3"]
        inventoryLocationId             <- map["InventoryLocationId"]
        isFreeShippingOverride          <- map["IsFreeShippingOverride"]
        isMm                            <- map["IsMm"]
        isRefundRequested               <- map["IsRefundRequested"]
        isTaxInvoiceBack                <- map["IsTaxInvoiceBack"]
        itemAmount                      <- map["ItemAmount"]
        lastCreated                     <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                    <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastName                        <- map["LastName"]
        locationExternalCode            <- map["LocationExternalCode"]
        logoImage                       <- map["LogoImage"]
        merchantId                      <- map["MerchantId"]
        mmCouponAdjustmentAmount        <- map["MMCouponAdjustmentAmount"]
        order                           <- map["Order"]
        orderDiscountAdjustmentAmount   <- map["OrderDiscountAdjustmentAmount"]
        orderDisputeReasonId            <- map["OrderDisputeReasonId"]
        orderReturnConditionId          <- map["OrderReturnConditionId"]
        orderReturnHistories            <- map["OrderReturnHistories"]
        orderReturnItems                <- map["OrderReturnItems"]
        orderReturnKey                  <- map["OrderReturnKey"]
        orderReturnReasonId             <- map["OrderReturnReasonId"]
        orderReturnResponseId           <- map["OrderReturnResponseId"]
        orderReturnStatusCode           <- map["OrderReturnStatusCode"]
        orderReturnStatusId             <- map["OrderReturnStatusId"]
        orderTransactionKey             <- map["OrderTransactionKey"]
        shippingAdjustmentAmount        <- map["ShippingAdjustmentAmount"]
        userKey                         <- map["UserKey"]
        userName                        <- map["UserName"]
        
        orderReturnStatus               <- (map["OrderReturnStatusId"], EnumTransform<OrderReturnStatus>())
        
        if let orderReturnHistories = orderReturnHistories {
            orderReturnSubmitCount = orderReturnHistories.filter({ $0.orderReturnStatus == .returnAuthorized }).count
        }
        
        if let orderReturnHistories = orderReturnHistories {
            orderDisputeSubmitCount = orderReturnHistories.filter({ $0.orderReturnStatus == .returnDisputed }).count
        }
    }
    
    func getImages() ->  [String] {
        let images = [self.image1 , self.image2 , self.image3]
        var validImages = [String]()
        
        for image in images {
            if !image.isEmpty {
                validImages.append(image)
            }
        }
        
        return validImages
    }
    
    func getSortedOrderHistories() -> [OrderReturnHistory] {
        // Get latest order return history for each status
        let lastestReturnCreatedOrderReturnHistory = self.getLastestOrderHistory(notificationEvent: Constants.NotificationEvent.returnRequested)
        let lastestReturnAuthorizedOrderReturnHistory = self.getLastestOrderHistory(notificationEvent: Constants.NotificationEvent.returnAuthorized)
        let lastestDisputeCreatedOrderReturnHistory = self.getLastestOrderHistory(notificationEvent: Constants.NotificationEvent.disputeSubmitted)
        let lastestDisputeInProgressOrderReturnHistory = self.getLastestOrderHistory(notificationEvent: Constants.NotificationEvent.disputeProgress)
        
        // Get rest order return histories
        let restOrderReturnHistories = (orderReturnHistories ?? []).filter {
            Constants.NotificationEvent.getReturnEnumType($0.orderReturnStatusCode) != Constants.NotificationEvent.returnRequested &&
            Constants.NotificationEvent.getReturnEnumType($0.orderReturnStatusCode) != Constants.NotificationEvent.returnAuthorized &&
            Constants.NotificationEvent.getReturnEnumType($0.orderReturnStatusCode) != Constants.NotificationEvent.disputeSubmitted &&
            Constants.NotificationEvent.getReturnEnumType($0.orderReturnStatusCode) != Constants.NotificationEvent.disputeProgress
        }
        
        var sortedOrderReturnHistories = [OrderReturnHistory]()

        if lastestReturnCreatedOrderReturnHistory != nil{
            sortedOrderReturnHistories.append(lastestReturnCreatedOrderReturnHistory!)
        }
        
        if lastestReturnAuthorizedOrderReturnHistory != nil{
            sortedOrderReturnHistories.append(lastestReturnAuthorizedOrderReturnHistory!)
        }
        
        if lastestDisputeCreatedOrderReturnHistory != nil{
            sortedOrderReturnHistories.append(lastestDisputeCreatedOrderReturnHistory!)
        }
        
        if lastestDisputeInProgressOrderReturnHistory != nil{
            sortedOrderReturnHistories.append(lastestDisputeInProgressOrderReturnHistory!)
        }
        
        sortedOrderReturnHistories.append(contentsOf: restOrderReturnHistories)
        sortedOrderReturnHistories.sort(by: {$0.lastCreated < $1.lastCreated})
        
        return sortedOrderReturnHistories
    }
    
    func getLastestOrderHistory(notificationEvent: Constants.NotificationEvent) -> OrderReturnHistory? {
        let filterReturnHistories = (orderReturnHistories ?? []).filter{Constants.NotificationEvent.getReturnEnumType($0.orderReturnStatusCode) == notificationEvent}
        return filterReturnHistories.sorted(by: {$0.lastCreated > $1.lastCreated}).first
    }
    
    func getReturnCompleteOrderHistory() -> OrderReturnHistory? {
        let filterReturnHistories = (orderReturnHistories ?? []).filter {
            Constants.NotificationEvent.getReturnEnumType($0.orderReturnStatusCode) == Constants.NotificationEvent.returnAccepted ||
            Constants.NotificationEvent.getReturnEnumType($0.orderReturnStatusCode) == Constants.NotificationEvent.returnRejected ||
            Constants.NotificationEvent.getReturnEnumType($0.orderReturnStatusCode) == Constants.NotificationEvent.returnRequestRejected
        }
        
        return filterReturnHistories.sorted(by: {$0.lastCreated > $1.lastCreated}).first
    }
}
