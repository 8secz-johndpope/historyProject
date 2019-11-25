//
//  ReferenceService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class ReferenceService{
    
    @discardableResult
    class func changeLanguage(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/reference/changelanguage"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
