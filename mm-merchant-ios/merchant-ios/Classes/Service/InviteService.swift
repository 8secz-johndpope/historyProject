//
//  InviteService.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 8/5/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//


import Foundation
import Alamofire


class InviteService {
    
    static let INVITE_PATH = Constants.Path.Host + "/invite"
    
    @discardableResult
    class func checkInviteCode(_ inviteCode: String, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = INVITE_PATH + "/code/check"
        let parameters: [String: Any] = ["InviteCode": inviteCode]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func saveInviteRequest(_ name: String,mobileCode: String, mobileNumber: String, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = INVITE_PATH + "/request/save"
        let parameters: [String: Any] = ["Name": name,"MobileCode": mobileCode, "MobileNumber": mobileNumber]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in complete(response)}
        return request
    }
}
