//
//  KuaiDi100ShipmentStatus.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 19/9/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class KuaiDi100ShipmentStatus: Mappable {
    
    var com = ""
    var condition = ""
    var data = [KuaiDi100Data]()
    var ischeck = ""
    var message = ""
    var nu = ""
    var state = ""
    var status = ""
    
    required convenience init?(map: Map) {
        self.init()
    }
    
    // Mappable
    func mapping(map: Map) {
        
        com             <- map["com"]
        condition       <- map["condition"]
        data            <- map["data"]
        ischeck         <- map["ischeck"]
        message         <- map["message"]
        nu              <- map["nu"]
        state           <- map["state"]
        status          <- map["status"]
        
    }
    
    func getStateMessage() -> String {
        if let state = Int(state) {
            switch state {
            case 0:
                return String.localize("LB_SHIPMENT_DESC_SHIPPING")
            case 1:
                return String.localize("LB_SHIPMENT_DESC_PICKED")
            case 2:
                return String.localize("LB_SHIPMENT_DESC_PROBLEM")
            case 3:
                return String.localize("LB_SHIPMENT_DESC_RECEIVE_SIGNED")
            case 4:
                return String.localize("LB_SHIPMENT_DESC_RETURN_SIGNED")
            case 5:
                return String.localize("LB_SHIPMENT_DESC_DISPATCHING")
            case 6:
                return String.localize("LB_SHIPMENT_DESC_RETURNING")
            default:
                break
            }
        }
        
        return String.localize("LB_SHIPMENT_NO_TRACKING_INFO")
    }
    
}
