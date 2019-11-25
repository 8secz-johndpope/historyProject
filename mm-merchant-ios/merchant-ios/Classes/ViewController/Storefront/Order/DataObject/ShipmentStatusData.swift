//
//  ShipmentStatusData.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 7/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class ShipmentStatusData {

    var orderShipment: Shipment?
    private var order: Order
    private var shipmentStatus: KuaiDi100ShipmentStatus?
    
    init(order: Order, orderShipment: Shipment?) {
        self.order = order
        self.orderShipment = orderShipment
    }
    
    // MARK: Data
    func getUpdatedStatus(_ completion: @escaping ((_ status: KuaiDi100ShipmentStatus?) -> Void)){
        if let orderShipment = orderShipment {
            var courierData: CourierData?
            
            if let data = orderShipment.courierData {
                courierData = data
            } else if let data = orderShipment.consolidationCourierData {
                courierData = data
            }
            
            if let courierData = courierData {
                firstly {
                    return fetchShipmentStatus(withCourierData: courierData)
                    }.then { [weak self] _ -> Void in
                        if let shipmentStatus = self?.shipmentStatus {
                            completion(shipmentStatus)
                        }else{
                            completion(nil)
                        }
                    }.catch { _ -> Void in
                        
                }
            }
        }
    }
    
    
    private func fetchShipmentStatus(withCourierData courierData: CourierData) -> Promise<Any> {
        return Promise { fulfill, reject in
            KuaiDi100Service.listShipmentStatus(withCourierCode: courierData.courierCode, consignmentNumber: courierData.consignmentNumber, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let shipmentStatus = Mapper<KuaiDi100ShipmentStatus>().map(JSONObject: response.result.value) {
                                strongSelf.shipmentStatus = shipmentStatus
                            }
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    }
                }
            })
        }
    }
}
