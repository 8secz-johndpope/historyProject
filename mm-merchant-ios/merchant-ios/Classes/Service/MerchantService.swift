//
//  MerchantService.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 3/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Alamofire
import PromiseKit
import ObjectMapper


enum MerchantListOrder {
    case all, featuredRedZone, featuredBlackZone
}

class MerchantService {
    
    @discardableResult
    class func view(_ id: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/search/merchant?id=\(id)"
        let request = RequestFactory.get(url, appendUserKey: false)
        
        request.exResponseJSON { response in
            // try to cache all user object
            if response.result.isSuccess && response.response?.statusCode == 200 {
                if let merchant = Mapper<Merchant>().map(JSONObject: response.result.value) {
                    CacheManager.sharedManager.cacheObject(merchant.cacheableObject())
                }
            }
            completion(response)
        }
        
        return request
    }
    
    @discardableResult
    class func getProductListOfMerchant(_ merchantId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/search/style?badgeid=1&pageno=1&pagesize=20&merchantid=\(merchantId)"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        
        return request
    }
    
    @discardableResult
    class func fetchMerchantBrands(_ merchantId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/search/merchant/brand?merchantid=\(merchantId)"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        
        return request
    }
    
    class func fetchMerchantsIfNeeded(_ listType: MerchantListOrder = .all) -> Promise<[Merchant]> {
        return Promise{ fulfill, reject in
            
            if CacheManager.sharedManager.merchantPoolReady {
                fulfill(MerchantService.filterArray(Array(CacheManager.sharedManager.merchantArrayPool), listType: listType))
                return
            }
            
            CacheManager.sharedManager.fetchAllMerchants({
                fulfill(MerchantService.filterArray(Array(CacheManager.sharedManager.merchantArrayPool), listType: listType))
            })
        }
    }
    
    
    private class func filterArray(_ merchants: [Merchant], listType: MerchantListOrder) -> [Merchant] {
        
        switch (listType) {
            case .all:
                
                return merchants
                
            case .featuredRedZone:
                
//                let sortedMerchants = merchants.sorted { $0.priorityRed > $1.priorityRed }
//                return merchants.filter { $0.merchantId > 0 && $0.isFeaturedRed }
                return merchants
            case .featuredBlackZone:
                
                let sortedMerchants = merchants.sorted { $0.priorityBlack > $1.priorityBlack }
                return sortedMerchants.filter { $0.merchantId > 0 && $0.isFeaturedBlack }
        }
        
    }
    
    class func fetchMerchantIfNeeded(_ merchantId: Int, completion: @escaping (_ merchant: Merchant?) -> Void) {
        if let merchant = CacheManager.sharedManager.cachedMerchantForId(merchantId) {
            Log.debug("Hit cache : merchant id : \(merchantId)")
            completion(merchant)
        } else {
            Log.debug("Missing cache : merchant key : \(merchantId)")
            
            view(merchantId, completion: { (response) in
                if response.response?.statusCode == 200 && response.result.isSuccess {
                    if let list = response.result.value as? [[String: Any]], let first = list.first, let merchant = Mapper<Merchant>().map(JSONObject: first) {
                        completion(merchant)
                    } else {
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            })
        }
	}
	
    @discardableResult
    class func viewMerchantSubdomain(_ merchantsubdomain: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/search/merchant?merchantsubdomain=\(merchantsubdomain)"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        
        return request
    }
    
    class func viewListWithMerchantIDs(_ merchantIDs: [Int], completion: @escaping ([Merchant], [Int : Merchant]) -> Void) {
        var promise = [Promise<Merchant?>]()
        
        for id in merchantIDs {
            promise.append(Promise<Merchant?> { fufill, fail in
                CacheManager.sharedManager.merchantById(id, completion: { merchantObject in
                    fufill(merchantObject)
                })
            })
        }
        
        when(fulfilled: promise).then { (merchants) -> Void in
            var map = [Int: Merchant]()
            var list = [Merchant]()
            
            for optionalMerchant in merchants {
                if let merchant = optionalMerchant {
                    map[merchant.merchantId] = merchant
                    list.append(merchant)
                }
            }
            
            completion(list, map)
        }
    }

}
