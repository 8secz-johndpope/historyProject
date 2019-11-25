//
//  Shipment.swift
//  merchant-ios
//
//  Created by Gambogo on 4/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class Shipment: Mappable {
    
    enum OrderShipmentStatus: Int {
        case unknown = 0
        case cancelled
        case shipped
        case pendingShipment
        case pendingCollection
        case received
        case collected
        case rejected
        case toShipToConsolidationCentre
        case shippedToConsolidationCentre
        case receivedToConsolidationCentre
    }
    
    var address = ""
    var city = ""
    var comments = ""
    var consignmentNumber = ""
    var consolidationConsignmentNumber = ""
    var consolidationCourierCode = ""
    var consolidationCourierId = ""
    var consolidationCourierName = ""
    var consolidationCourierMobileCode = ""
    var consolidationCourierMobileNumber = ""
    var consolidationLogoImage = ""
    var country = ""
    var courierCode = ""
    var courierId = 0
    var courierName = ""
    var courierMobileCode = ""
    var courierMobileNumber = ""
    var courierUrl = ""
    var cultureCode = ""
    var district = ""
    var inventoryLocationId = 0
    var isReviewSubmitted = false
    var lastCreated = Date()
    var lastModified = Date()
    var locationExternalCode = ""
    var logoImage = ""
    var orderShipmentItems: [ShipmentItem]?
    var orderShipmentKey = ""
    var orderShipmentStatusCode = ""
    var orderShipmentStatusId = 0
    var phoneCode = ""
    var phoneNumber = ""
    var postalCode = ""
    var province = ""
    var recipientName = ""
    var taxInvoiceName = ""
    var taxInvoiceNumber = ""
    
    var orderKey = ""
    var map: Map?
    var order: Order?
    
    var orderShipmentStatus: OrderShipmentStatus = .unknown
//    var sortedShipmentStatus: SortedShipmentStatus = .Unknown
	
    var isProcessedShipment = true
    
    var courierData: CourierData?
    var consolidationCourierData: CourierData?
    
    // Deprecated?
    var geoCityId = 0
    var geoCountryId = 0
    var geoProvinceId = 0
    var isTaxInvoiceRequested = false
    var orderShipmentNumber = ""
    var orderShipmentStatusName = ""

    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        self.map = map
        
        address                             <- map["Address"]
        city                                <- map["City"]
        comments                            <- map["Comments"]
        consignmentNumber                   <- map["ConsignmentNumber"]
        consolidationConsignmentNumber      <- map["ConsolidationConsignmentNumber"]
        consolidationCourierCode            <- map["ConsolidationCourierCode"]
        consolidationCourierId              <- map["ConsolidationCourierId"]
        consolidationCourierName            <- map["ConsolidationCourierName"]
        consolidationCourierMobileCode      <- map["ConsolidationCourierMobileCode"]
        consolidationCourierMobileNumber    <- map["ConsolidationCourierMobileNumber"]
        consolidationLogoImage              <- map["ConsolidationLogoImage"]
        country                             <- map["Country"]
        courierCode                         <- map["CourierCode"]
        courierId                           <- map["CourierId"]
        courierName                         <- map["CourierName"]
        courierMobileCode                   <- map["CourierMobileCode"]
        courierMobileNumber                 <- map["CourierMobileNumber"]
        courierUrl                          <- map["CourierUrl"]
        cultureCode                         <- map["CultureCode"]
        district                            <- map["District"]
        inventoryLocationId                 <- map["InventoryLocationId"]
        isReviewSubmitted                   <- map["IsReviewSubmitted"]
        lastCreated                         <- (map["LastCreated"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        lastModified                        <- (map["LastModified"], DateTransformExtension(dateFormat: DateTransformExtension.DateFormatStyle.dateTimeSimple))
        locationExternalCode                <- map["LocationExternalCode"]
        logoImage                           <- map["LogoImage"]
        orderShipmentItems                  <- map["OrderShipmentItems"]
        orderShipmentKey                    <- map["OrderShipmentKey"]
        orderShipmentStatusCode             <- map["OrderShipmentStatusCode"]
        orderShipmentStatusId               <- map["OrderShipmentStatusId"]
        phoneCode                           <- map["PhoneCode"]
        phoneNumber                         <- map["PhoneNumber"]
        postalCode                          <- map["PostalCode"]
        province                            <- map["Province"]
        recipientName                       <- map["RecipientName"]
        taxInvoiceName                      <- map["TaxInvoiceName"]
        taxInvoiceNumber                    <- map["TaxInvoiceNumber"]
        orderKey                            <- map["OrderKey"]
        order                               <- map["Order"]
        
        orderShipmentStatus                 <- (map["OrderShipmentStatusId"], EnumTransform<OrderShipmentStatus>())
		
        // Deprecated?
        geoCityId                           <- map["GeoCityId"]
        geoCountryId                        <- map["GeoCountryId"]
        geoProvinceId                       <- map["GeoProvinceId"]
        isTaxInvoiceRequested               <- map["IsTaxInvoiceRequested"]
        orderShipmentNumber                 <- map["OrderShipmentNumber"]
        orderShipmentStatusName             <- map["OrderShipmentStatusName"]
        
        if courierCode.length > 0 && courierName.length > 0 && consignmentNumber.length > 0 {
            courierData = CourierData(orderShipment: self, type: .normal)
        }
        
        if consolidationCourierCode.length > 0 && consolidationCourierName.length > 0 && consolidationConsignmentNumber.length > 0 {
            consolidationCourierData = CourierData(orderShipment: self, type: .consolidation)
        }
    }
    
    func copy() -> Shipment {
        let shipment = Shipment()
        shipment.mapping(map: map!)
        
        return shipment
    }
    

}
