//
//  LoyaltyService.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 2/27/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class LoyaltyService {
    static let LOYALTY_PATH = Constants.Path.Host + "/loyalty"
    static let MARKETING_LOYALTY_PATH = "https://cdnc.mymm.cn/marketing/vip"
    
    @discardableResult
    class func listLoyaltyStatus(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = LOYALTY_PATH + "/status/list"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func getLoyaltyPrivileges(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = MARKETING_LOYALTY_PATH + "/vip.json"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
