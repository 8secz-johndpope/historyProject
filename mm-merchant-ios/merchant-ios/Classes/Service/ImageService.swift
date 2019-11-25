//
//  PhotoService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 25/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

class ImageService {

    @discardableResult
    class func viewFullUrl(url : URLConvertible, completion : Response<UIImage, NSError> -> Void) -> DataRequest {
        let request = RequestFactory.get(url)
        request.responseImage{response in completion(response)}
        return request
    }

    @discardableResult
    class func view(key : String, completion : Response<UIImage, NSError> -> Void) -> DataRequest {
        return ImageService.view(key, size: 0, completion: completion)
    }
    
    @discardableResult
    class func view(key : String, size : Int, completion : Response<UIImage, NSError> -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/image/view"
        let parameters : [String:Any]
        if size > 0 {
            parameters = ["key" : key, "s" : String(size)]
        } else {
            parameters = ["key" : key]
        }        
        let request = RequestFactory.get(url, parameters : parameters)
        request.responseImage{response in completion(response)}
        return request
    }
    
}
  
