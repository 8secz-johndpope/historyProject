//
//  AddressService.swift
//  merchant-ios
//
//  Created by hungvo on 3/7/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Alamofire

class AddressService {
    
    static let ADDRESS_PATH = Constants.Path.Host + "/address"
    
    @discardableResult
    class func list(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ADDRESS_PATH + "/list"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func save(_ address : Address, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ADDRESS_PATH + "/save"
        let parameters: [String : Any] = ["RecipientName" : address.recipientName, "GeoCountryId" : address.geoCountryId, "GeoProvinceId": address.geoProvinceId, "GeoCityId": address.geoCityId, "PhoneCode": address.phoneCode, "PhoneNumber": address.phoneNumber, "IsDefault": address.isDefault, "Address": address.address, "PostalCode" : address.postalCode]
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: true, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func delete(_ userAddressKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ADDRESS_PATH + "/delete"
        let parameters: [String : Any] = ["UserAddressKey" : userAddressKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func change(_ address : Address, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ADDRESS_PATH + "/save"
        let parameters: [String : Any] = ["UserAddressKey" : address.userAddressKey, "RecipientName" : address.recipientName, "GeoCountryId" : address.geoCountryId, "GeoProvinceId": address.geoProvinceId, "GeoCityId": address.geoCityId, "PhoneCode": address.phoneCode, "PhoneNumber": address.phoneNumber, "IsDefault": address.isDefault, "Address": address.address, "PostalCode" : address.postalCode]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func viewDefault(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ADDRESS_PATH + "/default/view"
        let request = RequestFactory.get(url)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func saveDefault(_ userAddressKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ADDRESS_PATH + "/default/save"
        let parameters: [String : Any] = ["UserAddressKey" : userAddressKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
