//
//  BrandService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 23/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit
import ObjectMapper


enum BrandListOrder : String{
    case BrandName = "BrandName"
    case Priority = "Priority"
}


//Helper to call search brand api w/wo cache
class BrandService {
    static let BRAND_PATH = Constants.Path.Host + "/brand"
    
    // Search brand with keywords will be route to API directly due to search keywords functions unknown in client side
    @discardableResult
    class func fetchBrandsInstantly(_ keywords: String, zone: SearchZoneMode? = nil, pageSize: Int = Constants.Paging.All, pageNo: Int = 1, sort: BrandListOrder = .Priority, order: ComparisonResult = .orderedDescending) -> Promise<[Brand]> {
        return Promise{ fulfill, reject in
            SearchService.searchBrand(keywords, zone: zone, pageSize: pageSize, pageNo: pageNo, sort: sort.rawValue, order: (order == .orderedDescending ? "desc" : "asc") , completion: { (response) in
                if response.result.isSuccess {
                    let brands = Mapper<Brand>().mapArray(JSONObject: response.result.value) ?? []
                    fulfill(brands)
                } else {
                    reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                }
            })
        }
    }
    
    // Brands related helper function, accessing cache manager
    //zone: set zone for filtering by zone
    //brandIds: set brandIds for filtering by brandIds
    class func fetchAllBrandsIfNeeded(_ zone: SearchZoneMode? = nil, brandIds:[Int]? = nil, sort:BrandListOrder = .Priority, order: ComparisonResult = .orderedDescending)  -> Promise<[Brand]> {
        return Promise{ fulfill, reject in
            
            if CacheManager.sharedManager.brandPoolReady {
                fulfill(BrandService.filterArray(Array(CacheManager.sharedManager.brandPool.values), zone: zone, brandIds: brandIds, sort: sort, order: order))
                return
            }
            
            CacheManager.sharedManager.fetchAllBrands({
                fulfill(BrandService.filterArray(Array(CacheManager.sharedManager.brandPool.values), zone: zone, brandIds: brandIds, sort: sort, order: order))
            })
        }
    }
    
    //Fetch All Brand INSTANTLY
    //zone: set zone for filtering by zone
    //brandIds: set brandIds for filtering by brandIds
    class func fetchAllBrands(_ zone: SearchZoneMode? = nil, isFeaturedBrand: Bool? = nil, brandIds:[Int]? = nil, sort:BrandListOrder = .Priority, order: ComparisonResult = .orderedDescending)  -> Promise<[Brand]> {
        return Promise{ fulfill, reject in
            
            CacheManager.sharedManager.fetchAllBrands({
                fulfill(BrandService.filterArray(Array(CacheManager.sharedManager.brandPool.values), zone: zone, isFeaturedBrand: isFeaturedBrand, brandIds: brandIds, sort: sort, order: order))
            })
        }
    }
    
    //zone: set zone for filtering by zone
    //brandIds: set brandIds for filtering by brandIds
    private class func filterArray(_ brands: [Brand], zone: SearchZoneMode? = nil, isFeaturedBrand: Bool? = nil, brandIds:[Int]? = nil, sort:BrandListOrder, order: ComparisonResult) -> [Brand] {
        
        var results = brands
        
        if let currentFeatureBrand = isFeaturedBrand {
            results = results.filter { $0.isListedBrand /* aligned with AC/MC, should use isListedBrand instead of isFeaturedBrand */ == currentFeatureBrand }
        }
        
        if let currentZone = zone {
            results = results.filter { (currentZone == .black) ? $0.isBlack : $0.isRed }
        }
        
        if let brandIds = brandIds {
            results = results.filter { brandIds.contains($0.brandId)}
        }
        
        results.sort { (first, second) -> Bool in
            switch sort {
            case .BrandName:
                return first.brandName.localizedCompare(second.brandName) == order
            case .Priority:
                return order == .orderedDescending ? first.priority > second.priority : first.priority < second.priority
            }
        }
        
        return results
    }

	@discardableResult
	class func view(_ id : Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
		let url = Constants.Path.Host + "/search/brand?id=\(id)"
        let request = RequestFactory.get(url, appendUserKey: false)
		request.exResponseJSON{response in completion(response)}
		return request
		
	}
    
    @discardableResult
    class func viewBrandBySubdomain(_ brandsubdomain : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = Constants.Path.Host + "/search/brand?brandsubdomain=\(brandsubdomain)"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        return request
        
    }

}
