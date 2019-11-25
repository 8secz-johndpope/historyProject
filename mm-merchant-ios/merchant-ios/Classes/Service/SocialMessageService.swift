//
//  SocialMessageService.swift
//  merchant-ios
//
//  Created by HungPM on 9/13/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

class SocialMessageService: NSObject {
    
    static let Path = Constants.Path.Host + "/socialmessage/fe"
    static var latestTimestamp: TimeInterval?
    
    class func listSocialMessage(_ socialMessageTypeId: Int?, breakCache: Bool = false, success: @escaping ((_ value: SocialMessageResponse) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        
        let url = Path + "/list"
        var parameters = [String : Any]()
        if let socialMessageTypeId = socialMessageTypeId {
            parameters["socialmessagetypeid"] = socialMessageTypeId
        }
        
        if breakCache {
            latestTimestamp = Date().timeIntervalSince1970 //assign latest timestamp to break cache
        }
        
        if let timestamp = self.latestTimestamp {
            parameters["timestamp"] = timestamp
        }
        
        RequestFactory.requestWithObject(
            HTTPMethod.get,
            url: url,
            parameters: parameters,
            success: success,
            failure: failure
        )
        
    }
    
    class func readSocialMessage(_ lastMessageId: Int, success: @escaping ((_ value: ActivateResponse) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let url = Path + "/updateisread"
        let parameters: [String : Any] = ["SocialMessageId" : lastMessageId as Any]
        
        RequestFactory.requestWithObject(.post, url: url, parameters: parameters, success: success, failure: failure)
    }
}
