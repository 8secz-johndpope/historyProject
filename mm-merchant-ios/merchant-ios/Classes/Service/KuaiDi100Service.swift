//
//  KuaiDi100Service.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 19/9/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

class KuaiDi100Service {
    
    private static let Path = "http://poll.kuaidi100.com/poll"
    
    @discardableResult
    class func listShipmentStatus(withCourierCode courierCode: String, consignmentNumber: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/query.do"
        
        let customerKey = "9C80A15549D57CBD5E2A09B840587A10"
        let secretKey = "klMaVrZQ155"
        let param = "{\"com\":\"\(courierCode)\",\"num\":\"\(consignmentNumber)\"}"
        let signHash = "\(param)\(secretKey)\(customerKey)".md5().uppercased()
        
        let parameters: [String: Any] = ["customer" : customerKey, "sign" : signHash, "param" : param]
        let request = RequestFactory.networkManager.request(url, method: .post, parameters: parameters)

        request.exResponseJSON{response in
            background_async {
                completion(response)
            }
        }
        return request
    }
    
}
