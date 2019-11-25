//
//  OrderList.swift
//  merchant-ios
//
//  Created by Jerry Chong on 8/9/17.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderUnpaidList: Mappable {
    
    var hitsTotal = 0
    var pageTotal = 0
    var pageSize = 0
    var pageCurrent = 0
    var pageData: [ParentOrder]?
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        hitsTotal               <- map["HitsTotal"]
        pageTotal               <- map["PageTotal"]
        pageSize                <- map["PageSize"]
        pageCurrent             <- map["PageCurrent"]
        pageData                <- map["PageData"]
        
    }
}

///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
// MARK: Per Order
//class ParentUnpaidOrder: Mappable {
//    var parentOrderId = ""
//    var lastCreated: NSDate?
//    var mmCouponAmount: Double = 0
//    var orders: [UnpaidOrderMerchant]?
//    
//    required convenience init?(map: Map) {
//        self.init()
//    }
//
//    // Mappable
//    func mapping(map: Map) {
//        parentOrderId                   <- map["ParentOrderId"]
//        lastCreated                     <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
//        mmCouponAmount                  <- map["MMCouponAmount"]
//        orders                          <- map["Orders"]
//    }
//}
//
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
//
//// MARK: Per Merchant
//class UnpaidOrderMerchant: Mappable {
//    var orderId = 0
//    var parentOrderId = 0
//    var merchantId: Int = 0
//    var grandTotal: Double = 0
//    var couponAmount: Double = 0
//    var shippingTotal: Double = 0
//    var phoneCode = ""
//    var phoneNumber = ""
//    var recipientName = ""
//    var taxInvoiceName = ""
//    var address = ""
//    var country = ""
//    var province = ""
//    var city = ""
//    var district = ""
//    var comments = ""
//    var orderItems: [UnpaidOrderMerchantItem]?
//
//    required convenience init?(map: Map) {
//        self.init()
//    }
//    
//    func getSubTotal() -> Double {
//        guard let orderItems = self.orderItems else { return 0 }
//        var subTotal: Double = 0
//        for orderItem in orderItems {
//            subTotal += orderItem.unitPrice * Double(orderItem.qtyOrdered)
//        }
//        subTotal -= shippingTotal
//        subTotal -= couponAmount
//        return subTotal
//    }
//
//    
//    // Mappable
//    func mapping(map: Map) {
//        orderId                         <- map["OrderId"]
//        parentOrderId                   <- map["ParentOrderId"]
//        merchantId                      <- map["MerchantId"]
//        grandTotal                      <- map["GrandTotal"]
//        couponAmount                    <- map["CouponAmount"]
//        shippingTotal                   <- map["ShippingTotal"]
//        phoneCode                       <- map["PhoneCode"]
//        phoneNumber                     <- map["PhoneNumber"]
//        recipientName                   <- map["RecipientName"]
//        taxInvoiceName                  <- map["TaxInvoiceName"]
//        address                         <- map["Address"]
//        country                         <- map["Country"]
//        province                        <- map["Province"]
//        city                            <- map["City"]
//        district                        <- map["District"]
//        comments                        <- map["Comments"]
//        orderItems                      <- map["OrderItems"]
//    }
//}
//
/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////
//
//// MARK: Per Item
//class UnpaidOrderMerchantItem: Mappable {
//    var orderItemId = 0
//    var parentOrderId = 0
//    var orderId = 0
//    var skuName = ""
//    var colorName = ""
//    var sizeName = ""
//    var productImage = ""
//    var unitPrice: Double = 0
//    var qtyOrdered = 0
//
//    
//    required convenience init?(map: Map) {
//        self.init()
//    }
//    
//    // Mappable
//    func mapping(map: Map) {
//        orderItemId                         <- map["OrderItemId"]
//        parentOrderId                       <- map["ParentOrderId"]
//        orderId                             <- map["OrderId"]
//        skuName                             <- map["SkuName"]
//        colorName                           <- map["ColorName"]
//        sizeName                            <- map["SizeName"]
//        productImage                        <- map["ProductImage"]
//        unitPrice                           <- map["UnitPrice"]
//        qtyOrdered                          <- map["QtyOrdered"]
// 
//    }
//}




class SectionUnpaidOrderCellData{
    var datasource = [UnpaidOrderCellData]()
    init() {}

}

class UnpaidOrderCellData{
    enum UnpaidCellType {
        case unknown
        case merchant
        case merchantDetail
        case item
        case action
        case deliveryAddress
        case invoice
        case shipping
        case merchantCoupon
        case subtotal
        case comments
        case mmCoupon
        case alipyIcon
        
    }
    var type: UnpaidCellType = .unknown
    var content: Any? = nil
    var merchantId: Int = 0
    var parentOrder: ParentOrder?
    
    init() {}
    
    convenience init(type: UnpaidCellType, content: Any) {
        self.init()
        self.type = type
        self.content = content
        
    }
    
}
