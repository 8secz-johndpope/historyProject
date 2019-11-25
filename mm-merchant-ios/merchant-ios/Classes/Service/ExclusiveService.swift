//
//  ExclusiveService.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 8/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Alamofire
import PromiseKit
import ObjectMapper

class ExclusiveService {
    static let Path = Constants.Path.Host + "/campaign/public"
    
    @discardableResult
    private class func getCampaignList(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Path + "/list"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    static var cachedCampaigns : [Campaign]? = nil
    
    class func getCampaigns(completion complete:(() -> Void)? = nil) -> Promise<[Campaign]> {
        return Promise { fulfill, reject in
            
            if let campagins = cachedCampaigns {
                fulfill(campagins)
                return
            }
            
            ExclusiveService.getCampaignList({ (response) in
                if response.result.isSuccess{
                    
                    if response.response?.statusCode == 200 {
                        if let campaigns: Array<Campaign> = Mapper<Campaign>().mapArray(JSONObject: response.result.value) {
                            cachedCampaigns = campaigns
                            fulfill(campaigns)
                            
                            return
                        }
                        let error = NSError(domain: "", code: 0, userInfo: nil) //campagin not found
                        reject(error)
                        
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error ?? ExclusiveService.getError(response))
                }
                
            })
        }
    }

    
    class func getError(_ response : (DataResponse<Any>)) -> NSError {
        var statusCode = 0
        if let code = response.response?.statusCode {
            statusCode = code
        }
        return NSError(domain: "", code: statusCode, userInfo: nil)
    }
    
    
}
