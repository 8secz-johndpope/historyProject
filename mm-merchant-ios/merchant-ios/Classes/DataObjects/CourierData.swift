//
//  CourierData.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 4/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CourierData {
    
    enum CourierType {
        case normal
        case consolidation
    }
    
    var type: CourierType = .normal
    var courierCode = ""
    var courierName = ""
    var courierPhoneCode = ""
    var courierPhoneNumber = ""
    var courierImageName = ""
    var consignmentNumber = ""
    
    init(orderShipment: Shipment, type: CourierType = .normal) {
        self.type = type
        
        switch type {
        case .normal:
            courierCode = orderShipment.courierCode
            courierName = orderShipment.courierName
            courierPhoneCode = orderShipment.courierMobileCode
            courierPhoneNumber = orderShipment.courierMobileNumber
            courierImageName = orderShipment.logoImage
            consignmentNumber = orderShipment.consignmentNumber
        case .consolidation:
            courierCode = orderShipment.consolidationCourierCode
            courierName = orderShipment.consolidationCourierName
            courierPhoneCode = orderShipment.consolidationCourierMobileCode
            courierPhoneNumber = orderShipment.consolidationCourierMobileNumber
            courierImageName = orderShipment.consolidationLogoImage
            consignmentNumber = orderShipment.consolidationConsignmentNumber
        }
    }
    
}
