//
//  CheckoutInteractor.swift
//  merchant-ios
//
//  Created by Jerry Chong on 19/6/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

final class CheckoutInteractor {
    
    weak var presenter: CheckoutPresenter?
    
    // Get Data by cached data
    func getCachedMerchantsByMerchantIDs(_ merchantIds: [Int], completion: @escaping ([Merchant], [Int : Merchant]) -> ()) {
         MerchantService.viewListWithMerchantIDs(merchantIds, completion: completion)
    }
    
    // Get Data by api
    func getDefaultAddress(_ completion: ((_ success: Bool, _ address: Address?) -> ())?) {
        _ = AddressService.viewDefault({ (response) in
            let statusCode = response.response?.statusCode ?? 0 
            if response.result.isSuccess {
                if statusCode == 200 {
                    if let address = Mapper<Address>().map(JSONObject: response.result.value) {
                        CacheManager.sharedManager.selectedAddress = address
                        completion?(true, address)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        completion?(true, Address())
                    }
                } else {
                    completion?(false, nil)
                }
            } else {
                completion?(false, nil)
            }
        })
    }

    func getFetchBrand(_ brandId: Int, completion: ((_ success: Bool, _ brand: Brand?) -> ())?){
        _ = BrandService.view(brandId){ (response) in
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    if let array = response.result.value as? [[String: Any]], let obj = array.first , let brand = Mapper<Brand>().map(JSONObject: obj) {
                        completion?(true, brand)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                        completion?(true, nil)
                    }
                    
                }else{
                    completion?(false, nil)
                }
            } else {
                completion?(false, nil)
            }
        }
        
    }
    
    class func getSearchStyle(withStyleCodes styleCodes: [String], merchantIds: [String]) -> Promise<[Style]> {
        return Promise{ fulfill, reject in
            SearchService.searchStyleByStyleCodeAndMechantId(styleCodes.joined(separator: ","), merchantIds: merchantIds.joined(separator: ",")) { (response) in
                if response.result.isSuccess {
                    if let response = Mapper<SearchResponse>().map(JSONObject: response.result.value), let styles = response.pageData {
                        fulfill(styles)
                    } else {
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                    }
                    
                    let error = NSError(domain: "", code: 401, userInfo: nil)
                    reject(error)
                } else {
                    reject(response.result.error!)
                }
            }
        }
    }
 
}
