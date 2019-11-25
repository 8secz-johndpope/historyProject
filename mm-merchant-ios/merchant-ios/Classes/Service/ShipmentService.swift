//
//  ShipmentService.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 11/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

class ShipmentService {
    
    static let SHIPMENT_PATH = Constants.Path.Host + "/order/shipment"
    
    @discardableResult
    class func receive(orderShipmentKey: String, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SHIPMENT_PATH + "/receive"
        let parameters: [String: Any] = ["OrderShipmentKey" : orderShipmentKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func view(orderShipmentKey: String, merchantId: Int? = nil, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SHIPMENT_PATH + "/view"
        var parameters: [String: Any] = ["OrderShipmentKey" : orderShipmentKey]
        var request: DataRequest
        if let merchantid = merchantId {
            parameters["merchantid"] = merchantid
            request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        }
        else {
            request = RequestFactory.get(url, parameters: parameters)
        }
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
