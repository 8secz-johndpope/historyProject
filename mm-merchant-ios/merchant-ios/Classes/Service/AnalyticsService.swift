//
//  AnalyticsService.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/7/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import GZIP

class AnalyticsService {
    
    class func post(_ data: [[String: Any]], success: @escaping (DataResponse<Any>) -> Void, fail: @escaping (Error) -> Void) {
        if let url = URL(string: Constants.Path.AnalyticsHost + "/t") {
            
            let data = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted) as NSData
            
            //打印埋点数据
            if Platform.DeveloperMode {
                var str = String.init(data: data! as Data, encoding: String.Encoding.utf8)
                str = str!.replacingOccurrences(of: "\n", with: "")
                str = str!.replacingOccurrences(of: " ", with: "")
                print("==================================\n\(str!)\n==================================")
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            request.setValue("gzip", forHTTPHeaderField: "Content-Encoding")
            request.httpBody = data?.gzippedData(withCompressionLevel: 0.3)
            
            RequestFactory.networkManager.request(request).responseJSON(completionHandler: { (response) in
                switch response.result {
                case .success:
                    if let JSON = response.result.value {
                        Log.debug("JSON: \(JSON)")
                    }
                    success(response)
                case .failure(let error):
                    fail(error)
                }
            })
            
        } else {
            let error = NSError(domain: "NSURL", code: 0, userInfo: nil)
            
            fail(error)
            Log.debug("NSURL Error")
        }
    }

}
