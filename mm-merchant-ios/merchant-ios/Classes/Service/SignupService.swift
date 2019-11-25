//
//  SignupService.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/3.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper

class SignupService {
    
    class func getsms(mobileCode:String,mobileNumber:String,success: @escaping ((_ value: MobileVerification) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let params:[String : String] = ["MobileCode":mobileCode,"MobileNumber":mobileNumber]
        let url = "https://" + Constants.Path.Domain + "/api/auth/sms/get"
        RequestFactory.requestWithObject(.post, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: success, failure: failure)
    }
    
    class func signup(mobileCode:String,mobileNumber:String,mobileVerificationId:String,mobileVerificationToken:String,success: @escaping ((_ value: Token) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let params:[String : String] = ["MobileCode":mobileCode,"MobileNumber":mobileNumber,"MobileVerificationId":mobileVerificationId,"MobileVerificationToken":mobileVerificationToken]
        let url = "https://" + Constants.Path.Domain + "/api/auth/sms/login"
        RequestFactory.requestWithObject(.post, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: success, failure: failure)
    }
//    , responseData: @escaping (_ data: DataResponse<Any>) -> void)
    class func wechatSigup(mobileCode:String,mobileNumber:String,mobileVerificationId:String,mobileVerificationToken:String,success: @escaping ((_ value: Token) -> Void), failure: @escaping (_ error: Error) -> Bool) {
        let params:[String : String] = ["MobileCode":mobileCode,"MobileNumber":mobileNumber,"MobileVerificationId":mobileVerificationId,"MobileVerificationToken":mobileVerificationToken,"AccessToken":Context.getToken(),"UserKey":""]//服务端要求
        let url = "https://" + Constants.Path.Domain + "/api/auth/activate/wechat"
        RequestFactory.requestWithObject(.post, url: url,parameters:params, appendUserKey: false, appendUserId: false, success: success, failure: failure)
    }
    
    
}
