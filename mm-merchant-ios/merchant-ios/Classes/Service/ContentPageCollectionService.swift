//
//  ContentPageCollectionService.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/20/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper


class ContentPageCollectionService {
    
    
    static let CONTENT_PAGE_COLLECTION_PATH = Constants.Path.Host + "/contentpagecollection"
    
    @discardableResult
    class func listContentPageCollection(_ typeId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params: [String: Any] = ["typeid": typeId]
        let url = CONTENT_PAGE_COLLECTION_PATH + "/public/list"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    
    
}
