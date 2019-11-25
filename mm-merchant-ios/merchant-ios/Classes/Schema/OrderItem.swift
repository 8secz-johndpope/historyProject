//
//  OrderItem.swift
//  merchant-ios
//
//  Created by Gambogo on 4/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderItem: Mappable {
    
    var barcode = ""
    var brandId = 0
    var colorId = 0
    var colorKey = ""
    var colorName = ""
    var isSale = false
    var itemTotal: Double = 0
    var lastCreated = Date()
    var lastModified = Date()
    var merchantId = 0
    var orderItemKey = ""
    var priceRetail: Double = 0
    var priceSale: Double = 0
    var productImage = ""
    var qtyCancelled = 0
    var qtyConfirmed = 0
    var qtyOrdered = 0
    var qtyReceived = 0
    var qtyReturned = 0
    var qtyReturnRequested = 0
    var qtyShipped = 0
    var qtyShippedPending = 0
    var qtyToShip = 0
    var sizeId = 0
    var sizeName = ""
    var skuCode = ""
    var skuId = 0
    var skuName = ""
    var styleCode = ""
    var unitPrice: Double = 0
    
    // Deprecated?
    var qtyAssigned = 0
    var qtyDisputed = 0
    var orderItemDiscount: Double = 0
    
    var qtyCancelRequested = 0  // Calculated from OrderStatus.CancelRequested
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        barcode                     <- map["Barcode"]
        brandId                     <- map["BrandId"]
        colorId                     <- map["ColorId"]
        colorKey                    <- map["ColorKey"]
        colorName                   <- map["ColorName"]
        isSale                      <- map["IsSale"]
        itemTotal                   <- map["ItemTotal"]
        lastModified                <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastCreated                 <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        merchantId                  <- map["MerchantId"]
        orderItemKey                <- map["OrderItemKey"]
        priceRetail                 <- map["PriceRetail"]
        priceSale                   <- map["PriceSale"]
        productImage                <- map["ProductImage"]
        qtyCancelled                <- map["QtyCancelled"]
        qtyConfirmed                <- map["QtyConfirmed"]
        qtyOrdered                  <- map["QtyOrdered"]
        qtyReceived                 <- map["QtyReceived"]
        qtyReturned                 <- map["QtyReturned"]
        qtyReturnRequested          <- map["QtyReturnRequested"]
        qtyShipped                  <- map["QtyShipped"]
        qtyShippedPending           <- map["QtyShippedPending"]
        qtyToShip                   <- map["QtyToShip"]
        sizeId                      <- map["SizeId"]
        sizeName                    <- map["SizeName"]
        skuCode                     <- map["SkuCode"]
        skuId                       <- map["SkuId"]
        skuName                     <- map["SkuName"]
        styleCode                   <- map["StyleCode"]
        unitPrice                   <- map["UnitPrice"]
        
        // Deprecated?
        qtyAssigned                 <- map["QtyAssigned"]
        qtyDisputed                 <- map["QtyDisputed"]
        orderItemDiscount           <- map["OrderItemDiscount"]
    }
    
}
