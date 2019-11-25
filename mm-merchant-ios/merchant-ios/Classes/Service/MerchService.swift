//
//  MerchService.swift
//  merchant-ios
//
//  Created by Hang Yuen on 9/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire

class MerchService {
    
    static let MERCH_PATH = Constants.Path.Host + "/merch"

    @discardableResult
    class func view(_ id : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = MERCH_PATH + "/view"
        let parameters = ["id" : id]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listAnswer(_ merchantId : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = MERCH_PATH + "/answer/list"
        let parameters = ["merchantid" : merchantId]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
