//
//  OrderCollectionData.swift
//  merchant-ios
//
//  Created by gam bogo on 4/10/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class OrderCollectionData {
    
    var collectionPhoneNumber = ""
    var collectionNumber = ""
    var orderShipment: Shipment? = nil
    var order: Order? = nil
    var inventoryLocation: InventoryLocation? = nil
    
    private var isFetchingInventoryLocation = false
    
    init(order: Order, orderShipment: Shipment?) {
        self.order = order
        self.orderShipment = orderShipment
        
        collectionNumber = order.orderKey
    }
    
    func getCollectionAddress() -> String {
        if let inventoryLocation = self.inventoryLocation {
            return inventoryLocation.formatAddress()
        }
        
        return ""
    }
    
    //Fetch Inventory Location if needed
    func fetchInBackgroundInventoryLocation(completion:@escaping ((Bool, InventoryLocation?) -> ())) {
        
        if isFetchingInventoryLocation {
            return
        }
        
        if let inventoryLocation = self.inventoryLocation {
            completion(true, inventoryLocation)
            return
        }
        
        if let order = self.order, let orderShipment = self.orderShipment {
            isFetchingInventoryLocation = true
            
            //Async loading inventory location for collection detail cell
            InventoryService.viewLocation(merchantId: order.merchantId, locationExternalCode: orderShipment.locationExternalCode, completion: { (response) in
                
                self.isFetchingInventoryLocation = false
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let inventoryLocation = Mapper<InventoryLocation>().map(JSONObject: response.result.value) {
                            self.inventoryLocation = inventoryLocation
                            completion(true, inventoryLocation)
                        }
                    }
                }
                completion(false, nil)
            })
        } else {
            completion(false, nil)
        }
    }
}
