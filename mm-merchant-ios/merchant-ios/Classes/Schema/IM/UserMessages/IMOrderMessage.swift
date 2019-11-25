//
//  IMOrderMessage.swift
//  merchant-ios
//
//  Created by Alan YU on 16/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

enum OrderShareType: String {
    case Unknown = "Unknown"
    case Order = "Order"
    case OrderShipment = "OrderShipment"
    case OrderReturn = "OrderReturn"
    case OrderCancel = "OrderCancel"
}

class IMOrderMessage: IMUserMessage {

    var orderType = OrderShareType.Unknown
    var orderReferenceNumber: String?
    var orderShipmentKey: String?
    
    override init() {
        super.init()
        dataType = .Order
    }
    
    convenience init(orderKey: String, orderReferenceNumber: String?, orderShipmentKey: String?, orderType: OrderShareType, convKey: String, myUserRole: UserRole?) {
        self.init()

        self.data = orderKey
        self.orderType = orderType
        self.orderReferenceNumber = orderReferenceNumber
        self.orderShipmentKey = orderShipmentKey
            
        self.convKey = convKey
        if let userRole = myUserRole {
            self.msgSenderMerchantId = userRole.merchantId
        }
    }
    
    override func JSONObject() -> [String : Any] {
        var parentJSONObject = super.JSONObject()

        parentJSONObject["OrderReferenceNumber"] = JSONOptionalValue(self.orderReferenceNumber)
        parentJSONObject["OrderType"] = self.orderType.rawValue
        if let orderShipmentKey = self.orderShipmentKey {
            parentJSONObject["OrderShipmentKey"] = orderShipmentKey
        }

        return parentJSONObject
    }
    
    override func toChatModel() -> ChatModel? {
        let message = ChatModel()
        
        message.messageId = messageKey
        message.chatSendId = senderUserKey
        message.convKey = convKey
        message.timeDate = timestamp
        message.dataType = dataType
        message.correlationKey = correlationKey
        message.orderType = orderType
        message.orderReferenceNumber = orderReferenceNumber
        message.orderShipmentKey = orderShipmentKey

        // Data must assign last
        message.dataBody = data
        
        return message
    }

}
