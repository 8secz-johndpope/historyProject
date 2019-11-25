//
//  RelationshipService.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Alamofire

class RelationshipService {
    
    
//    /api/view/relationship/user?UserKey=...&ToUserKey=...
//    /api/view/relationship/merchant?UserKey=...&ToMerchantId=...
//    /api/view/relationship/brand?UserKey=...&ToBrandId=...

    static let RELATIONSHIP_PATH = Constants.Path.Host + "/view/relationship"
    
    @discardableResult
    class func relationshipByUser(_ userKey : String,timestamp: Double, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = RELATIONSHIP_PATH + "/user"
        let parameters : [String : Any] = ["ToUserKey" : userKey, "t": "\(timestamp)"]
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func relationshipByMerchant(_ toMerchantId : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = RELATIONSHIP_PATH + "/Merchant?ToMerchantId=\(toMerchantId)"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func relationshipByBrand(_ toBrandId : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = RELATIONSHIP_PATH + "/Brand?ToBrandId=\(toBrandId)"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
