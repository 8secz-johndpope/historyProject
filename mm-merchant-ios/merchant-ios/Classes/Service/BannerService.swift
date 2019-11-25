//
//  BannerService.swift
//  merchant-ios
//
//  Created by Gam Bogo on 5/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import PromiseKit

class BannerService {
    
    static let BANNER_PATH = Constants.Path.Host + "/banner"
    private static var queueBanner = DispatchQueue(label: "mymm.banner.cache.queue", attributes: [])
    private static var safeBanners:[BannerCollectionType: [Banner]] = [:]
    
    private static var cachedBanners : [BannerCollectionType: [Banner]] {
        get {
            var results: [BannerCollectionType: [Banner]] = [:]
            queueBanner.sync {
                results = safeBanners
            }
            return results
        }
        set(value){
            queueBanner.async(flags: .barrier, execute: {
                safeBanners = value
            }) 
        }
    }
    
    @discardableResult
    private class func listBanner(_ bannerCollectionIds: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params: [String: Any] = ["bannercollectionid": bannerCollectionIds, "limit" : Constants.Paging.BannerOffset]
        let url = BANNER_PATH + "/public/list"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    //loadFromCache == true: load from cache
    //loadFromCache == false: force reload banners
    class func fetchBanners(_ collections: [BannerCollectionType], loadFromCache: Bool = false) -> Promise<[Banner]> {
        
        return Promise { fulfill, reject in
            
            
            if loadFromCache {
                var banners : [Banner] = []
                var validCache = true
                for collection in collections {
                    if let subsetBanners = cachedBanners[collection] {
                        banners += subsetBanners
                    } else {
                        validCache = false
                        break
                    }
                }
                
                if validCache {
                    fulfill(banners)
                    return
                }
            }
            
            let queryString = collections.map({ "\($0.rawValue)" }).joined(separator: ",")
            
            BannerService.listBanner(queryString, completion: { (response) in
                
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        DispatchQueue.global(qos: .default).async(execute: {() -> Void in
                            if let banners = Mapper<Banner>().mapArray(JSONObject: response.result.value) {
                                
                                for collection in collections {
                                    cachedBanners[collection] = []
                                }
                                banners.forEach({ (banner) in
                                    cachedBanners[banner.collectionType]?.append(banner)
                                })
                                
                                DispatchQueue.main.async {
                                    fulfill(banners)
                                }
                            }
                        })

                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error!)
                }
    
            })
        }

        
    }
    
    
}
