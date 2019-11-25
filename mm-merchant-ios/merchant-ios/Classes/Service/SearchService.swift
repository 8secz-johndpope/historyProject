//
//  SearchService.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 10/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

enum SearchZoneMode: String {
    case black = "black"
    case red = "red"
}

enum SortZoneMode: String {
    case PriorityRed = "PriorityRed"
    case PriorityBlack = "PriorityBlack"
}

class SearchService {
    
    static let SEARCH_PATH = Constants.Path.Host + "/search"
    
    @discardableResult
    private class func searchStyle(_ queryString: String? = nil, priceFrom: Int? = nil, priceTo: Int? = nil, brands: [Brand]? = nil, cats: [Cat]? = nil, colors: [Color]? = nil, sizes: [Size]? = nil, badges: [Badge]? = nil , merchants: [Merchant]? = nil, isSale: Int? = nil, isNew: Int? = nil, isCrossBorder: Int? = nil, notSoldOut: Int = 1, sort: String? = nil, order: String? = nil, zone: String? = nil, pageSize: Int = 9999, pageNo: Int = 1, merchantId: Int? = nil,skuIds: String? = nil, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/style"
        var parameters: [String : Any] = ["pagesize" : "\(pageSize)", "pageno" : "\(pageNo)"]
		
        if let queryString = queryString, queryString.length > 0{
            //MM-21650 App crashes when searching with %
            if let decodedString = queryString.removingPercentEncoding {
                //MM-20820 Deeplink not filtering properly when specified PLP with keyword and merchantid
                parameters["s"] = decodedString
            } else {
                parameters["s"] = queryString
            }
        }
        
        if let priceFrom = priceFrom{
            parameters["pricefrom"] = priceFrom
        }
        else{
            parameters["pricefrom"] = "0"
        }
        
        if let priceTo = priceTo{
            parameters["priceto"] = priceTo
        }
        
        if let merchantid = merchantId {
            parameters["merchantid"] = merchantid
        }
        
        if brands != nil && brands?.isEmpty == false {
                var bait = ""
                for brand: Brand in brands! {
                    bait += String(brand.brandId)
                    bait += ","
                }
                bait =  String(bait.dropLast())
                parameters["brandid"] = bait
        } else {//简单解决 MM-33243 此问题，防止超出100的品牌不再显示
            parameters["aggsize"] = "1000"
        }
        
        if cats != nil {
            if cats?.isEmpty == false {
                var bait = ""
                for cat: Cat in cats! {
                    bait += String(cat.categoryId)
                    bait += ","
                }
                bait =  String(bait.dropLast())
                parameters["categoryid"] = bait
            }
        }
        
        if colors != nil {
            if colors?.isEmpty == false {
                var bait = ""
                for color: Color in colors! {
                    bait += String(color.colorId)
                    bait += ","
                }
                bait =  String(bait.dropLast())
                parameters["colorid"] = bait
            }
        }
        
        if sizes != nil {
            if sizes?.isEmpty == false {
                var bait = ""
                for size: Size in sizes! {
                    bait += String(size.sizeId)
                    bait += ","
                }
                bait =  String(bait.dropLast())
                parameters["sizeid"] = bait
            }
        }
        
        if badges != nil {
            if badges?.isEmpty == false {
                var bait = ""
                for badge: Badge in badges! {
                    bait += String(badge.badgeId)
                    bait += ","
                }
                bait =  String(bait.dropLast())
                parameters["badgeid"] = bait
            }
        }
        
        if merchants != nil {
            if merchants?.isEmpty == false {
                var bait = ""
                for merchant: Merchant in merchants! {
                    bait += String(merchant.merchantId)
                    bait += ","
                }
                bait =  String(bait.dropLast())
                parameters["merchantid"] = bait
            }
        }
        
        if isSale != nil  && (isSale == 1 || isSale == 0) {
            parameters["issale"] = isSale
        }
        
        if isNew != nil && (isNew == 1 || isNew == 0) {
            parameters["isnew"] = isNew
        }
        
        if isCrossBorder != nil && (isCrossBorder == 1 || isCrossBorder == 0) {
            parameters["iscrossborder"] = isCrossBorder
        }
        
        if notSoldOut == 1 || notSoldOut == 0 {
            parameters["notsoldout"] = notSoldOut
        }
        
        if sort != nil && sort != "" {
            parameters["sort"] = sort
        } else {
            parameters["sort"] = "DisplayRanking"
        }
        
        if order != nil && order != "" {
            parameters["order"] = order
        }
        else{
            parameters["order"] = "desc"
        }
        
        if !(zone ?? "").isEmpty {
            parameters["zone"] = zone
        }

        if skuIds != nil {
            parameters["skuid"] = skuIds
        }
        Log.debug(parameters)
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchStyle(_ category: Cat,pageSize: Int = Constants.Paging.Offset, pageNo: Int = 1, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        return searchStyle(cats: [category], pageSize: pageSize, pageNo: 1 , completion: completion)
    }
    
    @discardableResult
    class func searchStyle(_ styleFilter: StyleFilter,pageSize: Int = Constants.Paging.Offset, pageNo: Int = 1, merchantId:Int? = nil,skuIds: String? = nil, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
            
        return searchStyle(styleFilter.queryString, priceFrom: styleFilter.priceFrom, priceTo: styleFilter.priceTo, brands: styleFilter.brands, cats: styleFilter.cats, colors: styleFilter.colors, sizes: styleFilter.sizes, badges: styleFilter.badges, merchants: styleFilter.merchants, isSale: styleFilter.isSale, isNew: styleFilter.isNew, isCrossBorder: styleFilter.isCrossBorder, sort: styleFilter.sort, order: styleFilter.order, zone: styleFilter.zone, pageSize: pageSize, pageNo: pageNo, merchantId: merchantId,skuIds: skuIds, completion: completion)
    }
    
    @discardableResult
    class func searchStyleByStyleCodeAndMechantId(_ styleCode: String, merchantIds: String? = nil, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/style"
        var parameters : [String : Any] = ["stylecode" : styleCode]
        
        if let merchantId = merchantIds {
            parameters["merchantid"] = merchantId
        }
        
        parameters["pagesize"] = "300"
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in
            
            background_async {
                if response.result.isSuccess && response.response?.statusCode == 200 {
                    if let resposne = Mapper<SearchResponse>().map(JSONObject: response.result.value), let pageData = resposne.pageData, let style = pageData.first {
                        for sku in style.skuList {
                            CacheManager.sharedManager.cacheObject(style.cacheableObject(sku.skuId))
                        }
                    }
                }
                
                //我先简单的修改下
                DispatchQueue.main.async {
                    completion(response)
                }
                
            }
            
        }
        return request
    }
    
    class func fetchStyleIfNeeded(_ skuId: Int, completion: @escaping (_ style: Style?) -> Void) {
        if let style = CacheManager.sharedManager.cachedStyleForSkiId(skuId) {
            Log.debug("Hit cache : skuId : \(skuId)")
            completion(style)
        } else {
            Log.debug("Missing cache : skuId : \(skuId)")
            searchStyleBySkuId(
                skuId,
                completion: { response in
                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        if let resposne = Mapper<SearchResponse>().map(JSONObject: response.result.value), let pageData = resposne.pageData, let style = pageData.first {
                            completion(style)
                        } else {
                            completion(nil)
                        }
                    }
                    else {
                        completion(nil)
                    }
                }
            )
        }
    }
    
    @discardableResult
    class func searchStyleBySkuId(_ skuId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/style"
        let parameters : [String : Any] = ["skuid" : skuId]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{ response in
            if response.result.isSuccess && response.response?.statusCode == 200 {
                if let resposne = Mapper<SearchResponse>().map(JSONObject: response.result.value), let pageData = resposne.pageData, let style = pageData.first {
                    CacheManager.sharedManager.cacheObject(style.cacheableObject(skuId))
                }
            }
            completion(response)
        }
        return request
    }
    
    @discardableResult
    class func searchStyleBySkuIds(_ skuIds: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/style"
        let parameters : [String : Any] = ["skuid" : skuIds]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchComplete(_ s: String, pageSize: Int = Constants.Paging.Offset, pageNo: Int = 1, sort: String = "Priority", order: String = "asc", merchantId: Int? = nil, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/complete"
        var parameters : [String : Any] = ["pagesize" : pageSize, "pageno" : pageNo, "s" : s, "sort": sort , "order": order]
        if let merchantid = merchantId {
            parameters["merchantid"] = merchantid
        }
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchBrandCombined(_ s: String = "", pageNo: Int = 1, sort: String = "Priority", order: String = "desc", completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/brand/combined"
        let parameters : [String : Any] = ["pagesize" : "\(Constants.Paging.Offset)", "pageno" : "\(pageNo)", "s" : s, "sort" : sort, "order" : order]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchAllBrandCombined(_ s: String = "", pageNo: Int = 1, sort: String = "Priority", order: String = "desc", completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/brand/combined"
        let parameters : [String : Any] = ["pagesize" : "\(Constants.Paging.Offset)", "pageno" : "\(pageNo)", "s" : s, "sort" : sort, "order" : order, "showall" : "1"]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchAllBrand(pageSize: Int = Constants.Paging.All, pageNo: Int = 1, sort: String = "Priority", order: String = "desc", completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/brandV2"
        let parameters : [String : Any] = ["pagesize" : pageSize,
                                           "pageno" : pageNo,
                                           "s" : "",
                                           "sort" : sort,
                                           "order" : order,
                                           "zone" : "red"]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    
    @discardableResult
    class func searchBrand(_ s: String = "", zone: SearchZoneMode? = nil, pageSize: Int = Constants.Paging.All, pageNo: Int = 1, sort: String = "Priority", order: String = "desc", completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/brand"
        var parameters : [String : Any] = ["pagesize" : pageSize, "pageno" : pageNo, "s" : s, "sort" : sort, "order" : order]
        if let zone = zone {
            parameters["zone"] = zone.rawValue
        }
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchAllMerchants(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/merchant"
        var parameters : [String : Any] = ["s" : "" as Any]
        parameters["pagesize"] = Constants.Paging.MerchantOffset
        parameters["zone"] = "red"
        parameters["sort"] = "PriorityRed"
        parameters["order"] = "desc"
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchMerchant(_ s: String = "", zone: SearchZoneMode? = nil, pageSize: Int = Constants.Paging.MerchantOffset, pageNo: Int = 1, sort: String? = nil, order: String? = nil, brandId: Int = 0, priceTo: Int = 0, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/merchant"
        var parameters : [String : Any] = ["pagesize" : pageSize, "pageno" : pageNo, "s" : s]
        
        if let sort = sort{
            parameters["sort"] = sort
        }
        if let order = order {
             parameters["order"] = order
        }
        
        if brandId != 0 {
            parameters["brandid"] = brandId
        }
        if priceTo != 0 {
            parameters["pricefrom"] = 0
            parameters["priceto"] = priceTo
        }
        
        if let zone = zone {
            parameters["zone"] = zone.rawValue
        }

        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    //将二级catIds存储下来
    private static var _subCatIds:Set<Int> = Set<Int>()
    static func cacheSecondCategoryId(_ id: Int) {
        objc_sync_enter(_subCatIds)
        defer { objc_sync_exit(_subCatIds) }
        if !_subCatIds.contains(id) {
            _subCatIds.insert(id)
        }
    }
    static func isSecondCategoryId(_ id: Int) -> Bool {
        objc_sync_enter(_subCatIds)
        defer { objc_sync_exit(_subCatIds) }
        return _subCatIds.contains(id)
    }
    
    static func searchCategory(_ pageNo: Int, pageSize: Int = Constants.Paging.CategoryOffset, s: String? = "", sort : String? = "Priority",
                               success: @escaping (_ value: [Cat]) -> Void,
                               failure: @escaping (_ error: Error) -> Bool) {
        let url = SEARCH_PATH + "/category"
        let parameters : [String : Any] = ["pagesize" : pageSize,
                                           "pageno" : pageNo,
                                           "s" : s!,
                                           "sort" : sort!,
                                           "skipempty":"1"]
        
        
        //处理下返回数据
        let sccs:(_ value: [Cat]) -> Void = { (list) in
            
            //替换掉原始数据中的categoryName
            for cat in list {
                //仅仅重写二级类目类目名（增加男士/女士）
                if let categoryList = cat.categoryList {
                    for subCat in categoryList {
                        cacheSecondCategoryId(subCat.categoryId)
                        if subCat.isMale != 0 && subCat.isFemale == 0 {
                            subCat.categoryName = String.localize("LB_CA_CAT_M") + subCat.categoryName
                        } else if subCat.isMale == 0 && subCat.isFemale != 0 {
                            subCat.categoryName = String.localize("LB_CA_CAT_F") + subCat.categoryName
                        }
                    }
                }
            }
            
            success(list)
        }
        
        RequestFactory.requestWithArray(.get, url: url, parameters: parameters, appendUserKey: false, appendUserId: false, success: sccs, failure: failure)
    }
    
    
    
    static func searchCategoryByCategoryId( ids: [Int], success: @escaping ((_ value: [Cat]) -> Void), failure: @escaping ((_ error: Error) -> Bool))  {
        let url = SEARCH_PATH + "/category"
        var idString = ""
        for id in ids {
            idString = idString + String(id) + ","
        }
        if idString.length > 0{
            let index = idString.index(before: idString.endIndex)
            idString = String(idString[..<index])
        }
        let parameters : [String : Any] = ["id" : idString as Any]
        
        //处理下返回数据
        let sccs:(_ value: [Cat]) -> Void = { (list) in
            //替换掉原始数据中的categoryName
            for cat in list {
                //仅仅重写二级类目类目名（增加男士/女士）
                if isSecondCategoryId(cat.categoryId) {
                    if cat.isMale != 0 && cat.isFemale == 0 {
                        cat.categoryName = String.localize("LB_CA_CAT_M") + cat.categoryName
                    } else if cat.isMale == 0 && cat.isFemale != 0 {
                        cat.categoryName = String.localize("LB_CA_CAT_F") + cat.categoryName
                    }
                }
            }
            success(list)
        }
        
        RequestFactory.requestWithArray(.get, url: url, parameters: parameters, appendUserKey: false, success: sccs, failure: failure)
    }
    
    @discardableResult
    class func searchSize(_ s: String? = "", completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/size"
        let parameters : [String : Any] = ["pagesize" : Constants.Paging.All, "pageno" : 1, "s" : s!]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchColor(_ s: String? = "", completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/color"
        let parameters : [String : Any] = ["pagesize" : Constants.Paging.ProductPropertyOffset, "pageno" : 1, "s" : s!]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func searchBadge(_ s: String? = "", completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/badge"
        let parameters : [String : Any] = ["pagesize" : Constants.Paging.ProductPropertyOffset, "pageno" : 1, "s" : s!]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }

    @discardableResult
    class func searchRecommendedProducts(_ merchantId: Int, pageNo: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/style"
        //参考Android逻辑，合理
        //https://next.mymm.com/api/search/style?order=desc&badgeid=1&zone=none&merchantid=4262&notsoldout=1&pageno=1&pricefrom=0&aggsize=1000&sort=StyleId&pagesize=50&cc=CHS
        let parameters : [String : Any] = ["merchantid": merchantId,
                                           "pageno" : pageNo,
                                           "pagesize" : Constants.LimitNumber.RecommendedProduct,
                                           "badgeid": 1,
                                           "notsoldout":1,
                                           "order":"desc",
                                           "sort":"DisplayRanking",
                                           "aggsize":1000
                                           ]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func getLikesProduct(styleIDs: [String], completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = SEARCH_PATH + "/style/activity/count/list"
        let parameters : [String : Any] = ["styleids": styleIDs.joined(separator: ",")]
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
}
