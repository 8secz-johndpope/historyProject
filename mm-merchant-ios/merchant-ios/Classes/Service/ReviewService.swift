//
//  ReviewService.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/6/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire

class ReviewService {
    
    struct ReviewSku {
        var skuId = ""
        var description = ""
        var rating = 0
        var images = [UIImage]()
        
    }
    
    static let REVIEW_PATH = Constants.Path.Host + "/review"
    
    @discardableResult
    class func viewSummaryReview(merchantId: Int, styleCode: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = REVIEW_PATH + "/sku/summary"
        let parameters: [String: Any] = [
            "MerchantId" : merchantId,
            "StyleCode" : styleCode
        ]
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listReview(merchantId: Int, styleCode: String, rating: Int = 0, isShowReviewWithImageOnly: Bool = false, pageNo: Int = 1, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = REVIEW_PATH + "/sku/public/list"
        var parameters: [String: Any] = [
            "MerchantId" : merchantId,
            "StyleCode" : styleCode,
            "Page" : pageNo,
        ]
        
        if rating > 0 {
            parameters["Rating"] = rating
        }
        
        if isShowReviewWithImageOnly {
            parameters["IsReviewWithImage"] = 1
        }
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func listMyReview(atPage page: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = REVIEW_PATH + "/sku/public/list"
        let parameters: [String: Any] = [
            "Page" : page
        ]
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    class func createReview(orderKey: String, reviewSkus: [ReviewSku], productDescriptionRating: Int, serviceRating: Int, logisticsRating: Int, npsRating: Int, success: @escaping (DataResponse<Any>) -> Void, failure: @escaping (Error) -> Void) {
        let url = REVIEW_PATH + "/create"
        
        var parameters: [String: Any] = [
            "OrderShipmentKey": orderKey as Any,
            "UserKey": Context.getUserKey() as Any,
            "ProductDescriptionRating": "\(productDescriptionRating)" as Any,
            "ServiceRating": "\(serviceRating)" as Any,
            "LogisticsRating": "\(logisticsRating)" as Any,
            "CorrelationKey": Utils.UUID() as Any
        ]
        
        //NPS is optional if nps > 0 send it to server
        if npsRating > 0 {
            parameters["NpsRating"] = "\(npsRating)"
        }
        
        RequestFactory.networkManager.upload(
            multipartFormData:  { multipartFormData in
                
                for indexSku in 0 ..< reviewSkus.count {
                    let reviewSku = reviewSkus[indexSku]
                    
                    // Append product review
                    
                    multipartFormData.append("\(reviewSku.skuId)".data(using: String.Encoding.utf8)!, withName: "Skus[\(indexSku)][SkuId]")
                    multipartFormData.append(reviewSku.description.data(using: String.Encoding.utf8)!, withName: "Skus[\(indexSku)][Description]")
                    multipartFormData.append("\(reviewSku.rating)".data(using: String.Encoding.utf8)!, withName: "Skus[\(indexSku)][Rating]")
                    
                    // Append image
                    var i = 0
                    for image in reviewSku.images {
                        if let imageData = UIImageJPEGRepresentation(image, Constants.CompressionRatio.JPG_COMPRESSION) {
                            multipartFormData.append(imageData, withName: "Image_\(reviewSku.skuId)", fileName: "Image_\(reviewSku.skuId)_\(i).jpg", mimeType: "image/jpg")
                            i += 1
                        }
                    }
                }
                
                for (key, value) in parameters {
                    if let stringValue = value as? String {
                        multipartFormData.append(stringValue.data(using: String.Encoding.utf8)!, withName: key)
                    } else {
                        // This case never reach but to make sure anything is fine
                        // Parse anything to string to make sure won't crash
                        multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key)
                    }
                }
                
            },
            to: url,
            method: .post,
            headers: Context.getHTTPHeader(Constants.AppVersion),
            encodingCompletion: { encodingResult in
                
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseJSON { response in
                        Log.debug(response.request)
                        Log.debug(response.response)
                        Log.debug(response.data)
                        Log.debug(response.result)
                        
                        Log.debug(response.result.value)
                        
                        success(response)
                    }
                case .failure(let encodingError):
                    Log.debug(encodingError)
                    
                    failure(encodingError)
                }
                
            }
        )
        
    }
    
    @discardableResult
    class func getMerchantReview(merchantId: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = REVIEW_PATH + "/merchant/summary"
        let parameters: [String: Any] = [
            "merchantId" : merchantId
        ]
        
        let request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func submitReportReview(reportReasonId: Int, reportDescription: String, skuReviewKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = REVIEW_PATH + "/report/create"
        let parameters: [String: Any] = [
            "Description" : reportDescription,
            "SkuReviewKey": skuReviewKey,
            "ReportReasonId": reportReasonId,
            "UserKey" : Context.getUserKey()
        ]
        
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func getReviewReportReasonList(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = REVIEW_PATH + "/report/reason/list"
        
        let request = RequestFactory.get(url, parameters: nil, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }

   
}
