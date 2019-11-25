//
//  CountryService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 16/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire


class CountryService {
    enum Op: Int {
        
        case getAllCountries
        
    }
    
    @discardableResult
    class func request(_ op : Op, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let request = RequestFactory.networkManager.request(Constants.Path.CountryHost, method: .get)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func list(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/reference/general"
        let request = RequestFactory.get(url, parameters : nil)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
