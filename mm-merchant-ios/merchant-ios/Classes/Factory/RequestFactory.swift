//
//  RequestFactory.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 27/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper


class RequestFactory {
    
    static let networkManager: SessionManager = {
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = SessionManager.defaultHTTPHeaders
        configuration.timeoutIntervalForRequest = 60
        var serverTrustPolicies: [String: ServerTrustPolicy] = [:]
        
        if Constants.Path.TrustAnyCert {
            for domain in Constants.Path.ignoreSSLDomains {
                serverTrustPolicies[domain] = .disableEvaluation
            }
        }
        
        return SessionManager(
            configuration: configuration,
            serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies)
        )
    }()
    
    
    
	class func get(_ url : URLConvertible, parameters : [String : Any]? = nil, appendUserKey: Bool = true, userKey: String? = nil) -> DataRequest {
        
        var factoryParameters: [String : Any] = ["cc" : Context.getCc() as Any]
        
        if appendUserKey {
			factoryParameters["userkey"] = Context.getUserKey()
        }
        
        if let key = userKey {
            factoryParameters["userkey"] = key
        }
        
        if let para = parameters {
            for (k, v) in para {
                factoryParameters[k] = v
            }
        }

        let request = networkManager.request(
            url,
            method: .get,
            parameters: factoryParameters,
            headers: Context.getHTTPHeader(Constants.AppVersion)
        )
        Log.debug(request)
        return request
    }
    
    @discardableResult
    class func post(_ url : URLConvertible, parameters : [String : Any]? = nil, appendUserKey: Bool = true, appendUserId: Bool = true) -> DataRequest {
        
        var factoryParameters: [String : Any] = ["cc" : Context.getCc() as Any, "CultureCode" : Context.getCc() as Any]
        
        if appendUserId {
            factoryParameters["UserId"] = Context.getUserId()
        }
        
        if appendUserKey {
            factoryParameters["UserKey"] = Context.getUserKey()
        }
        
        if let para = parameters {
            for (k, v) in para {
                factoryParameters[k] = v
            }
        }
        

        let request = networkManager.request(url, method: HTTPMethod.post, parameters: factoryParameters, encoding: JSONEncoding.default, headers: Context.getHTTPHeader(Constants.AppVersion))
        Log.debug(request)
        
        return request
    }
    
    class func requestWithObject<Value: Mappable>(
        _ method: Alamofire.HTTPMethod,
        url: URLConvertible,
        parameters: [String: Any]? = nil,
        appendUserKey: Bool = true,
        appendUserId: Bool = true,
        userKey: String? = nil,
        shouldShowErrorDialog: Bool = true,
        success: ((_ value: Value) -> Void)? = nil,
        failure: ((_ error: Error) -> Bool)? = nil
        ) {
        self.request(method,
                     url: url,
                     parameters: parameters,
                     appendUserKey: appendUserKey,
                     appendUserId: appendUserId,
                     userKey: userKey,
                     shouldShowErrorDialog: shouldShowErrorDialog,
                     success: success,
                     failure: failure)
    }
    
    class func requestWithArray<Value>(
        _ method: Alamofire.HTTPMethod,
        url: URLConvertible,
        parameters: [String: Any]? = nil,
        appendUserKey: Bool = true,
        appendUserId: Bool = true,
        userKey: String? = nil,
        success: ((_ value: [Value]) -> Void)? = nil,
        failure: ((_ error: Error) -> Bool)? = nil
        ) where Value : Mappable {
        self.request(method,
                     url: url,
                     parameters: parameters,
                     appendUserKey: appendUserKey,
                     appendUserId: appendUserId,
                     userKey: userKey,
                     isMapJSONArray: true,
                     successWithArray: success,
                     failure: failure)
    }
    
    class func requestWithArray(
        _ method: Alamofire.HTTPMethod,
        url: URLConvertible,
        parameters: [String: Any]? = nil,
        appendUserKey: Bool = true,
        appendUserId: Bool = true,
        userKey: String? = nil,
        success: ((_ value: [String]) -> Void)? = nil,
        failure: ((_ error: Error) -> Bool)? = nil
        ) {
        let scs:(_ value: [AdaptiveMappable]) -> Void = { (value) in }
        self.request(method,
                     url: url,
                     parameters: parameters,
                     appendUserKey: appendUserKey,
                     appendUserId: appendUserId,
                     userKey: userKey,
                     isMapJSONArray: true,
                     successStringArray: success,
                     successWithArray: scs,
                     failure: failure)
    }
    
    class func request<Value: Mappable>(
        _ method: Alamofire.HTTPMethod,
        url: URLConvertible,
        parameters: Parameters? = nil,
        appendUserKey: Bool = true,
        appendUserId: Bool = true,
        userKey: String? = nil,
        isMapJSONArray: Bool = false,
        shouldShowErrorDialog: Bool = true,
        success: ((_ value: Value) -> Void)? = nil,
        successStringArray: ((_ value: [String]) -> Void)? = nil,
        successWithArray: ((_ value: [Value]) -> Void)? = nil,
        failure: ((_ error: Error) -> Bool)? = nil
        ) {
        
        var factoryParameters: Parameters = ["cc" : Context.getCc() as Any]
        
        switch method {
        case .post :
            factoryParameters["CultureCode"] = Context.getCc()
            if appendUserId {
                factoryParameters["UserId"] = Context.getUserId()
            }
            if appendUserKey {
                factoryParameters["UserKey"] = Context.getUserKey()
            }
        case .get :
            if appendUserKey {
                factoryParameters["userkey"] = (userKey ?? Context.getUserKey())
            }
        default: break
        }
        
        if let para = parameters {
            for (k, v) in para {
                factoryParameters[k] = v
            }
        }
        
        var encoding: ParameterEncoding = URLEncoding.default
        if method == .post {
            encoding = JSONEncoding.default
        }
        
        let request = networkManager.request(
            url,
            method: method,
            parameters: factoryParameters,
            encoding: encoding,
            headers: Context.getHTTPHeader(Constants.AppVersion)
            )
            .validate().responseJSON(completionHandler: { (response) in
                
                if let api = response.request?.url {
                    Log.debug("Requesting API : \(api) \n \(response.timeline)")
                }
                
                AppUpgradeHelper.checkAppUpgrade(response)
                
                let handleError = { (error: Error) -> Void in
                    
                    //构建新的错误，将AppCode带回去
                    var info:[String:Any] = [:]
                    if let userInfo = error._userInfo as? [String:Any] {
                        info.mergeAll(userInfo)
                    }
                    if let validData = response.data, validData.count > 0,let json = try? JSONSerialization.jsonObject(with: validData),let resp = Mapper<ApiResponse>().map(JSONObject: json), let appCode = resp.appCode, !appCode.isEmpty {
                        info["AppCode"] = appCode as AnyObject
                    }
                    let domain = error._domain.isEmpty ? "SERVER" : error._domain
                    let err = NSError(domain: domain, code: error._code, userInfo: info)
                    
                    if failure == nil || (failure != nil && !failure!(err)) {
                        //因为Alamofire返回success必须是http返回200,这边并不标准，返回其他错误码时，同时还有body
                        if let validData = response.data, validData.count > 0,let json = try? JSONSerialization.jsonObject(with: validData),let resp = Mapper<ApiResponse>().map(JSONObject: json) {
                            if shouldShowErrorDialog {
                                self.handleApiResponseError(apiResponse: resp, statusCode: (response.response?.statusCode)!)
                            }
                        } else if let val = response.result.value, let resp = Mapper<ApiResponse>().map(JSONObject: val) {
                            if shouldShowErrorDialog {
                                self.handleApiResponseError(apiResponse: resp, statusCode: (response.response?.statusCode)!)
                            }
                        } else {
                            if shouldShowErrorDialog {
                                self.showApiErrorPrompt(Utils.formatErrorMessage(String.localize("MSG_ERR_NETWORK_FAIL"), error: error))
                            }
                        }
                        
                        //不应该在这里调用
                        if failure == nil && success != nil {
                            success?(Mapper<Value>().map(JSONString: "{}")!)
                        }
                    }
                }
                
                switch response.result {
                case .success(let JSON):
                    if isMapJSONArray, successStringArray != nil {
                        if let JSONArray = JSON as? [String] {
                            successStringArray?(JSONArray)
                        } else {
                            // this error should never happen
                            let userInfo = [NSLocalizedFailureReasonErrorKey: "Mapping failure due to not [String] response."]
                            let error = NSError(domain: "", code:/* AFError.responseSerializationFailed.rawValue*/ 2, userInfo: userInfo)
                            handleError(error)
                        }
                    } else if isMapJSONArray {
                        if let responseValue: [Value] = Mapper<Value>().mapArray(JSONObject: JSON) {
                            successWithArray?(responseValue)
                        } else {
                            // this error should never happen
                            let userInfo = [NSLocalizedFailureReasonErrorKey: "Mapping failure due to not [String: Any] or [[String: Any]] response."]
                            let error = NSError(domain: "", code:/* AFError.responseSerializationFailed.rawValue*/ 2, userInfo: userInfo)
                            handleError(error)
                        }
                    } else if let responseValue = Mapper<Value>().map(JSONObject: JSON) {
                        success?(responseValue)
                    } else {
                        // this error should never happen
                        let userInfo = [NSLocalizedFailureReasonErrorKey: "Mapping failure due to not [String: Any] or [[String: Any]] response."]
                        let error = NSError(domain: "", code:/* AFError.responseSerializationFailed.rawValue*/ 2, userInfo: userInfo)
                        handleError(error)
                    }
                case .failure(let error):
                   handleError(error)
                }
            })
        
        Log.debug(request)
    }
    
    class func upload (
        _ url: URLConvertible,
        file: (URL: URL, name: String, fileName: String, mimeType: String),
        parameters: [String : Any]? = nil,
        progress: ((Progress) -> Void)? = nil,
        success : @escaping (DataResponse<Any>) -> Void,
        fail : @escaping (Error) -> Void
        ) {
        networkManager.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(file.URL, withName: file.name, fileName: file.fileName, mimeType: file.mimeType)
            if let para = parameters {
                for (key, value) in para {
                    multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false)!, withName: key)
                }
            }
        }, to: url,
           method: .post,
           headers: Context.getHTTPHeader(Constants.AppVersion),
           encodingCompletion: { encodingResult in
            switch encodingResult {
            case .success(let request, _, _):
                if let progress = progress {
                    request.uploadProgress(closure: progress)
                }
                request.exResponseJSON(completionHandler: success)
                break
            case .failure(let encodingError):
                fail(encodingError)
                break
                
            }
        })
    }
    
    private class func handleApiResponseError(apiResponse: ApiResponse, statusCode: Int,  shouldShowErrorDialog: Bool = true) {
        
        if let appCode = apiResponse.appCode {
            if appCode == "MSG_ERR_USER_UNAUTHORIZED" {
                self.topViewController()?.showUnauthorizedAlert()
            }else {
                let skipErrors = ["MSG_ERR_WISHLIST_NOT_FOUND",
                                  "MSG_ERR_CART_NOT_FOUND",
                                  "MSG_ERR_USER_ADDRESS_EMPTY",
//                                  "MSG_ERR_USER_NOT_EXISTS",
                                  "MSG_ERR_USER_IDENTIFICATION_EMPTY"]
                if !skipErrors.contains(appCode) {
                    let msg = String.localize(appCode)
                    if shouldShowErrorDialog {
                        self.showApiErrorPrompt(msg/* == appCode ? String.localize("MSG_ERR_NETWORK_FAIL") : msg*/)
                    }
                    Log.debug(apiResponse.appCode)
                }
                
            }
            
        } else {
            if shouldShowErrorDialog {
                self.showApiErrorPrompt(String.localize("LB_ERROR"))
            }
        }
        
        
    }
    
    private class func showApiErrorPrompt(_ msg: String) {
        let vc :UIViewController = self.topViewController()!
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                var msgStr = String.localize("LB_ERROR")
                msgStr = msg
                vc.showErrorAlert(msgStr)
            })
            CATransaction.commit()
    }
    
    private class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? { //Fix: Cannot get top view controller to display Alert View
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}

fileprivate class AdaptiveMappable:Mappable {
    required init?(map: Map) {
        return nil
    }
    
    func mapping(map: Map) {
        //
    }
}
