//
//  BannerService.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 9/25/17.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import PromiseKit

class HashTagService {
    
    static let HASHTAG_PATH = Constants.Path.Host + "/tag"
    
    enum FeaturedTagTypeCode: String {
        case Post = "POST"
    }

    @discardableResult
    class func listFeatureTags(_ typeCode: FeaturedTagTypeCode, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params: [String: Any] = ["featuredtagtypecode": typeCode.rawValue]
        let url = HASHTAG_PATH + "/fe/featured/list"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    
}
