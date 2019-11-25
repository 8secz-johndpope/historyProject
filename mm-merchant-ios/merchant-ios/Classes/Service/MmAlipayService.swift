//
//  MmAlipayService.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 10/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire

class MmAlipayService {
    
    private static let PATH = Constants.Path.Host + "/alipay"
    
    @discardableResult
    class func createSign(_ alipayCreateSign: AlipayCreateSign, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = PATH + "/payment/create"
        let jsonString = Mapper().toJSONString(alipayCreateSign, prettyPrint: true)
        var urlRequest = URLRequest(url: URL(string: url)!)
        
        var httpHeaders = Context.getHTTPHeader(Constants.AppVersion)
        httpHeaders["Content-Type"] = "application/json"
        
        urlRequest.allHTTPHeaderFields = httpHeaders
        urlRequest.httpBody = jsonString!.data(using: String.Encoding.utf8, allowLossyConversion: true)
        urlRequest.httpMethod = "POST"
        
        Log.debug(urlRequest.httpBody)
        
        let request = RequestFactory.networkManager.request(urlRequest)
        request.exResponseJSON{response in completion(response)}
        
        return request
    }

    @discardableResult
    class func verify(_ alipayVerifyRequest: AlipayVerifyRequest, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = PATH + "/payment/verify"
        let jsonString = Mapper().toJSONString(alipayVerifyRequest, prettyPrint: true)
        var urlRequest = URLRequest(url: URL(string: url)!)
        
        var httpHeaders = Context.getHTTPHeader(Constants.AppVersion)
        httpHeaders["Content-Type"] = "application/json"
        
        urlRequest.allHTTPHeaderFields = httpHeaders
        urlRequest.httpBody = jsonString!.data(using: String.Encoding.utf8, allowLossyConversion: true)
        urlRequest.httpMethod = "POST"
        
        Log.debug(urlRequest.httpBody)
        
        let request = RequestFactory.networkManager.request(urlRequest)
        request.exResponseJSON{response in completion(response)}
        
        return request
    }
    
}
