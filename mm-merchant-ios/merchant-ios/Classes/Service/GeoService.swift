//
//  GeoService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class GeoService {
    
    static let GEO_PATH = Constants.Path.Host + "/geo"
    
    @discardableResult
    class func storefrontCountries(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = GEO_PATH + "/country/storefront"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON(5){response in completion(response)}
        return request
    }
    
    @discardableResult
    class func storefrontProvinces(_ geoCountryId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = GEO_PATH + "/province?q=\(geoCountryId)"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func storefrontCities(_ geoProvinceId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = GEO_PATH + "/city?q=\(geoProvinceId)"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
}
