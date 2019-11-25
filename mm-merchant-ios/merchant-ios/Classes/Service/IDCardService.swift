//
//  IDCardService.swift
//  merchant-ios
//
//  Created by Kam on 11/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

class IDCardService {
    static let IDCARD_PATH = Constants.Path.Host + "/identification"
    
    class func uploadIDCardInfo(_ orderKey : String, firstName : String, lastName : String, idNumber : String, frontImage : Data? = nil, backImage : Data? = nil, success : @escaping (DataResponse<Any>) -> Void, fail : @escaping (Error) -> Void) {
        let url = IDCARD_PATH + "/save"
        let parameters: [String : String] = [
            "UserKey" : Context.getUserKey(),
            "OrderKey" : orderKey,
            "FirstName" : firstName,
            "LastName": lastName,
            "IdentificationNumber": idNumber
        ]
        
        RequestFactory.networkManager.upload(
            multipartFormData: { multipartFormData in
                
                if let front = frontImage {
                    multipartFormData.append(front, withName: "FrontImage", fileName: "frontImage.jpg", mimeType: "image/jpg")
                }
                if let back = backImage {
                    multipartFormData.append(back, withName: "BackImage", fileName: "backImage.jpg", mimeType: "image/jpg")
                }
                for (key, value) in parameters {
                    multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
                }
                
            },
            to: url,
            method: .post,
            headers: Context.getHTTPHeader(Constants.AppVersion),
            encodingCompletion: { encodingResult in
                
                switch encodingResult {
                case .success(let upload, _, _):
                    Log.debug("Success")
                    
                    upload.responseJSON { response in
                        Log.debug(response.request)  // original URL request
                        Log.debug(response.response) // URL response
                        Log.debug(response.data)     // server data
                        Log.debug(response.result)   // result of response serialization
                        
                        if let JSON = response.result.value {
                            Log.debug("JSON: \(JSON)")
                        }
                        
                        success(response)
                    }
                    
                case .failure(let encodingError):
                    Log.debug(encodingError)
                    
                    fail(encodingError)
                }
            }
        )
        
    }
    
    class func getIdentification(_ userKey: String, success: @escaping ((_ value: Identification) -> Void), failure: ((_ error: Error) -> Bool)? = nil) {
        let params: [String: Any] = ["userkey": userKey as Any]
        
        let url = IDCARD_PATH + "/view"
        RequestFactory.requestWithObject(.get, url: url, parameters: params, appendUserKey: false, shouldShowErrorDialog: false, success: success, failure: failure)
    }
}

