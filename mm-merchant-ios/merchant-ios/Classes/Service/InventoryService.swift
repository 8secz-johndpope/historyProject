//
//  InventoryService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 30/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class InventoryService {
    
    static let INVENTORY_PATH = Constants.Path.Host + "/inventory"

    @discardableResult
    class func view(_ id : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = INVENTORY_PATH + "/location/view"
        let parameters = ["id" : id]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func viewLocation(merchantId: Int, locationExternalCode: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = INVENTORY_PATH + "/location/public/view"
        let parameters: [String : Any] = ["merchantid" : merchantId, "locationexternalcode": locationExternalCode]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func list(_ userKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = INVENTORY_PATH + "/location/list/user"
        let parameters = ["userkey" : userKey]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
}
