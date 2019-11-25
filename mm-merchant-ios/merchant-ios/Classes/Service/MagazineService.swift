//
//  MagazineService.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 5/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class MagazineService {
    
    static let MAGAZINE_PATH = Constants.Path.Host + "/contentpage"
    
    class func magazineCoverList(typeId: Int, collectionId: Int?, page: Int, size: Int,
                                        success: @escaping ((_ value: MagazineCoverList) -> Void),
                                        failure: @escaping (_ error: Error) -> Bool) {
        var params: [String: Any] = ["typeid": typeId as Any, "page": page as Any, "size": size as Any]
        
        if collectionId != nil {
            params["collectionId"] = collectionId
        }
        
        let url = MAGAZINE_PATH + "/public/list"
        RequestFactory.requestWithObject(.get, url: url, parameters: params, appendUserKey: false, success: success, failure: failure)
    }
    
    @discardableResult
    class func listMagazineCover(typeId: Int, collectionId: Int?, page: Int, size: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        var params: [String: Any] = ["typeid": typeId, "page": page, "size": size]
        
        if collectionId != nil {
            params["collectionId"] = collectionId
        }
        
        let url = MAGAZINE_PATH + "/public/list"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listMagazineCollection(_ typeId: Int, collectionId: Int, page: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let params: [String: Any] = ["typeid": typeId, "page": page, "collectionId": collectionId]
        let url = MAGAZINE_PATH + "collection/public/list"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func viewContentPage(_ pageKey: String , completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params: [String: Any] = ["contentpagekey": pageKey, "cc": Context.getCc()]
        let url = MAGAZINE_PATH + "/public/view"
        let request = RequestFactory.get(url, parameters: params, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    /**
     get my content page list
     
     - parameter userkey:    my user key
     - parameter completion:
     
     - returns: request
     */
    @discardableResult
    class func viewContentPageListByUserKey (pageIndex: Int, size: Int = Constants.Paging.Offset, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = MAGAZINE_PATH + "/liked/list"
        let params : [String: Any] = ["page": pageIndex, "size": size]
		let request = RequestFactory.get(url, parameters: params, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
        
    }
    
    static func viewLikeContentPageListByUserKey(pageKeys:[String], success: @escaping ((_ value: [String]) -> Void)) {
        let url = MAGAZINE_PATH + "/checkliked"
        let params : [String: Any] = ["pagekeys": pageKeys.joined(separator: ",")]
        RequestFactory.requestWithArray(.get, url: url, parameters: params, appendUserKey: true, success: success, failure: nil)
    }
    
    @discardableResult
    class func unlikePageContent (page: MagazineCover, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let url = MAGAZINE_PATH + "/like"
        let params : [String: Any] = ["ContentPageKey": page.contentPageKey, "IsLike" : 0]
        let request = RequestFactory.post(url, parameters: params, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
        
    }
    
    @discardableResult
    class func actionLikeMagazine(_ isLike: Int , contentPageKey: String,  completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        let params:[String : Any] = ["CultureCode": Context.getCc(), "ContentPageKey": contentPageKey, "IsLike" : isLike]
        let url = MAGAZINE_PATH + "/like"
        let request = RequestFactory.post(url, parameters: params, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
