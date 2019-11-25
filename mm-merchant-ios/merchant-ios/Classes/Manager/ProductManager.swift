//
//  StyleManager.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 6/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Kingfisher

class ProductManager {
    class func searchStyleWithSkuIds(_ skuIds: String) -> Promise<[Style]> {
        return Promise{ fulfill, reject in
            SearchService.searchStyleBySkuIds(skuIds) { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        var listStyle = [Style]()
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                            if let styles = styleResponse.pageData {
                                if styles.count > 0 {
                                    listStyle += styles
                                }
                            }
                        }
                        fulfill(listStyle)
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                    
                }
            }
        }
    }
    
    class func searchStyleWithSkuId(_ skuId: Int) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchStyleBySkuId(skuId) { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value){
                            if let styles = styleResponse.pageData {
                                if styles.count > 0 {
                                    fulfill(styles[0])
                                }
                            }
                        }
                        
                        fulfill("OK")
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    class func searchStyleWithStyleCode(_ styleCode: String, merchantIds: [String]) -> Promise<Any> {
        return Promise{ fulfill, reject in
            SearchService.searchStyleByStyleCodeAndMechantId(styleCode, merchantIds: merchantIds.joined(separator: ",")) { (response) in
                if response.result.isSuccess {
                    if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                        if let styles = styleResponse.pageData {
                            if styles.count > 0 {
                                fulfill(styles[0])
                            }
                        }
                    }
                    
                    fulfill("OK")
                } else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
//    class func searchStyle(withStyleCodes styleCodes: [String]) -> Promise<Any> {
//        return Promise{ fulfill, reject in
//            SearchService.searchStyle(withStyleCodes: styleCodes) { (response) in
//                if response.result.isSuccess {
//                    if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
//                        if let styles = styleResponse.pageData {
//                            fulfill(styles)
//                        }
//                    }
//                    
//                    fulfill("OK")
//                } else {
//                    reject(response.result.error!)
//                }
//            }
//        }
//    }
    @discardableResult
    class func setProductImage(imageView productImageView: UIImageView, style: Style?, colorKey: String, size: ResizerSize = ResizerSize.size512, placeholderImage: Image? = nil, completion: ((_ image: Image?, _ error: NSError?) -> ())? = nil) -> String {
        var imageKeyIsValid = false
        var imageKey = ""
        
        if let defaultSku = style?.defaultSku() {
                        
            if let key = style?.findImageKeyByColorKey(colorKey) {
                imageKey = key
            } else {
                if let key = style?.findImageKeyByColorKey(defaultSku.colorKey) {
                    imageKey = key
                }
            }
            
            if imageKey != "" {
                imageKeyIsValid = true
                
                productImageView.mm_setImageWithURL(ImageURLFactory.URLSize(size, key: imageKey), placeholderImage: placeholderImage, clipsToBounds: true, contentMode: .scaleAspectFit, progress: nil, optionsInfo: nil, completion: { (image, error, cacheType, imageURL) in
                    if let completion = completion {
                        completion(image, error)
                    }
                })
            }
        }
        
        if !imageKeyIsValid {
            productImageView.image = placeholderImage
            
            if let completion = completion {
                completion(nil, nil)
            }
        }
        
        return imageKey
    }
    
    class func getProductImageKey(_ style: Style, colorId: Int) -> String {
        if let key = style.findSuitableImageKey(colorId) {
            return key
        }
        
        return ""
    }
    
    class func getProductImageKey(_ style: Style, colorKey: String) -> String{
        if let _ = style.defaultSku() {
            if let key = style.findImageKeyByColorKey(colorKey) {
                return key
            }
        }
        
        return ""
    }
    
    class func setProductImage(imageView productImageView: UIImageView, style: Style, skuId: Int) {
        if let defaultSku = style.defaultSku() {
            let sku = style.findSkuBySkuId(skuId)
            ProductManager.setProductImage(imageView: productImageView, style: style, colorKey: sku?.colorKey ?? defaultSku.colorKey)
        }
    }
    
    class func fetchStyles(_ styleFilter: StyleFilter, pageSize: Int, pageNo: Int, completion: (([Style], NSError?) -> Void)? = nil){
        SearchService.searchStyle(styleFilter, pageSize: pageSize, pageNo: pageNo) { (response) in
            if let styleResponse = Mapper<SearchResponse>().map(JSONObject: response.result.value) {
                if let styles = styleResponse.pageData {
                    completion?(styles, nil)
                } else {
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    completion?([], nil)
                }
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .FailToParseAPIResponse)
                if let err = response.result.error as NSError? {
                    completion?([], err)
                } else {
                    completion?([], nil)
                }
            }
        }
    }
}
