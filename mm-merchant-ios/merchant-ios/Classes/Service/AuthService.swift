//
//  MmService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/9/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import ObjectMapper



class AuthService {
    struct SignUpParameter {
        static let MobileNumber = "MobileNumber"
        static let MobileCode = "MobileCode"
        static let MobileVerificationId = "MobileVerificationId"
        static let MobileVerificationToken = "MobileVerificationToken"
        static let UserName = "UserName"
        static let Password = "Password"
        static let DisplayName = "DisplayName"
        static let InviteCode = "InviteCode"
        static let DeviceId = "DeviceId"
        
        var mobileNumber = ""
        var mobileCode = ""
        var mobileVerificationId = -1
        var mobileVerificationToken = ""
        var password = ""
        var displayName = ""
        var inviteCode : String?
        
        
        func jsonFormat() -> [String : Any] {
            var parameters = [String : Any]()
            parameters[AuthService.SignUpParameter.MobileNumber] = self.mobileNumber
            parameters[AuthService.SignUpParameter.MobileCode] = self.mobileCode
            parameters[AuthService.SignUpParameter.MobileVerificationId] = self.mobileVerificationId
            parameters[AuthService.SignUpParameter.MobileVerificationToken] =  self.mobileVerificationToken
            parameters[AuthService.SignUpParameter.Password] = self.password
            parameters[AuthService.SignUpParameter.DisplayName] = self.displayName
            if let invite = self.inviteCode {
                parameters[AuthService.SignUpParameter.InviteCode] = invite
            }
            parameters[AuthService.SignUpParameter.DeviceId] = JPUSHService.registrationID() ?? ""
            
            return parameters
        }
        
    }
    
    static let AUTH_PATH = Constants.Path.Host + "/auth"
    
    class func requestSignup(_ parameters: AuthService.SignUpParameter) -> Promise<Token> {
        return Promise{ fulfill, reject in
            
            signup(parameters.jsonFormat(), completion: { (response) in
                if response.result.isSuccess && response.response?.statusCode == 200, let token = Mapper<Token>().map(JSONObject: response.result.value) {
                    fulfill(token)
                } else {
                    reject(parseLoginError(response))
                }
            })
            
        }
        
    }
    
    class func requestLogin(_ username: String, password: String) -> Promise<Token> {
        
        return Promise{ fulfill, reject in
            
            let parameters = [
                "Username" : username,
                "Password" : password,
            ]
            
            login(parameters, completion: { (response) in
                if response.result.isSuccess && response.response?.statusCode == 200, let token = Mapper<Token>().map(JSONObject: response.result.value) {
                    fulfill(token)
                } else {
                    reject(parseLoginError(response))
                }
            })
            
        }
    }
    
    
    //  Parsing the dirty respones to generate an NSError
    
    private class func parseLoginError(_ response: DataResponse<Any>) -> NSError {
        
        let statusCode = response.response?.statusCode ?? 0
        
        if response.result.isSuccess, let resp = Mapper<ApiResponse>().map(JSONObject: response.result.value){
            if let appCode = resp.appCode  {
                var msg: String = String.localize(appCode)
                var domain = ""
                if let range : Range<String.Index> = msg.range(of: "{0}") {
                    if let loginAttempts = resp.loginAttempts {
                        msg = msg.replacingCharacters(in: range, with:"\(Constants.Value.MaxLoginAttempts - loginAttempts)")
                        domain = "LoginAttemptExceed"
                    }
                }
                
                let errorInfo: [String: Any] = [
                    "error": msg,
                    NSLocalizedDescriptionKey: msg,
                    "isMobile": resp.isMobile,
                    "appCode": appCode
                ]
                
                return NSError(domain: domain, code: statusCode, userInfo: errorInfo)
                
            } else {
                return NSError(domain: "ErrorMessageCorrupt", code: 8003, userInfo: nil)
            }
        } else {
            
            let msg = Utils.formatErrorMessage(
                String.localize("MSG_ERR_NETWORK_FAIL"),
                error: response.result.error
            )
            return NSError(domain: "", code: statusCode, userInfo: ["error":msg, NSLocalizedDescriptionKey: msg])
        }
    }
    
    @discardableResult
    private class func login(_ parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        var newParameters = parameters
        newParameters[SignUpParameter.DeviceId] = JPUSHService.registrationID() ?? ""
        
        return post(AUTH_PATH + "/login", parameters: newParameters, completion: completion)
        
    }
    
    @discardableResult
    class func loginWeChat(_ parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        var newParameters = parameters
        newParameters[SignUpParameter.DeviceId] = JPUSHService.registrationID() ?? ""
        
        return post(AUTH_PATH + "/login/wechat", parameters: newParameters, completion: completion)
        
    }
    
    @discardableResult
    class func activateWeChat(_ parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        var newParameters = parameters
        if newParameters["UserKey"] == nil {
            newParameters["UserKey"] = "" //服务端要求
        }
        newParameters[SignUpParameter.DeviceId] = JPUSHService.registrationID() ?? ""
        
        return post(AUTH_PATH + "/activate/wechat", parameters: newParameters, completion: completion)
        
    }
    
    @discardableResult
    class func resetPassword(_ parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        return post(AUTH_PATH + "/reset", parameters: parameters, completion: completion)
        
    }
    
    @discardableResult
    class func reactivateCode(_ parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        return post(AUTH_PATH + "/code/reactivate", parameters: parameters, completion: completion)
    }
    
    @discardableResult
    class func sendMobileVerification(_ parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        return post(AUTH_PATH + "/mobileverification/send", parameters: parameters, completion: completion)
    }
    
    @discardableResult
    class func checkMobileVerification(_ parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        return post(AUTH_PATH + "/mobileverification/check", parameters: parameters, completion: completion)
    }
    
    @discardableResult
    private class func signup(_ parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        var newParameters = parameters
        newParameters[SignUpParameter.DeviceId] = JPUSHService.registrationID() ?? ""
        
        return post(AUTH_PATH + "/signup", parameters: newParameters, completion: completion)
    }
    
    //MARK: Common post function for all auth services
    @discardableResult
    class func post(_ url : URLConvertible, parameters : [String : Any], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        //Making unauthenicated call
        let request = RequestFactory.networkManager.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
        Log.debug(request)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
}
