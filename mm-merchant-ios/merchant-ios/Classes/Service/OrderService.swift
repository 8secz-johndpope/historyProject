//
//  OrderService.swift
//  merchant-ios
//
//  Created by HungPM on 3/11/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper

class OrderService {
    
    enum AfterSalesHistoryType: Int {
        case cancel = 2
        case `return` = 4
    }
    
    enum AfterSalesType: Int {
        case cancel = 0
        case `return`
        case dispute
    }
    
    static let ORDER_PATH = Constants.Path.Host + "/order"
    static let RESOURCE_PATH = Constants.Path.Host + "/resource/get"
    
    // MARK: - Order
    
    @discardableResult
    class func listOrder(onViewMode viewMode: Constants.OmsViewMode, page: Int, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/mylist"
        let parameters: [String: Any] = ["page": "\(page)", "OrderStatusIds": getOrderStatusIds(viewMode: viewMode)]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func viewOrder(_ orderKey: String, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/view"
        let parameters: [String: Any] = ["OrderKey": orderKey]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func createOrder(_ userAddressKey: String, skus: [Dictionary<String,Any>], orders: [Dictionary<String,Any>], coupon: Coupon? = nil, isCart: Bool, isFlashSale: Bool = false, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/create"
        
        var parameters: [String: Any] = ["UserAddressKey": userAddressKey, "Skus": skus, "Orders": orders, "IsCart": isCart, "IsFlashSale": isFlashSale ? 1 : 0 ]
        if let cpsDic = CacheManager.sharedManager.getSmzdeCode() {
            parameters.mergeAll(cpsDic)
        }
        if let strongCoupon = coupon {
            parameters["MMCouponReference"] = strongCoupon.couponReference
        }
        let request = RequestFactory.post(url, parameters: parameters, appendUserId: false)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func checkOrder(_ userAddressKey: String, skus: [Dictionary<String,Any>], orders: [Dictionary<String,Any>], coupon: Coupon? = nil, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/check"
        var parameters: [String: Any] = ["UserAddressKey": userAddressKey, "Skus": skus, "Orders": orders]
        if let strongCoupon = coupon {
            parameters["MMCouponReference"] = strongCoupon.couponReference
        }
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    @discardableResult
    class func checkStock(_ skus: [Dictionary<String,Any>], orders: [Dictionary<String,Any>], coupon: Coupon? = nil, isFlashSale: Bool = false, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/check/stock"
        var parameters: [String: Any] = ["Skus": skus, "Orders": orders, "IsFlashSale": isFlashSale ? 1 : 0]
        if let strongCoupon = coupon {
            parameters["MMCouponReference"] = strongCoupon.couponReference
        }
        print("STOCK -> " + parameters.debugDescription)
        let request = RequestFactory.post(url, parameters: parameters)
        request.shouldShowErrorDialog = false
        request.exResponseJSON { response in
            complete(response)
        }
        return request
    }
    
    // MARK: - Unpaid Order
    
    @discardableResult
    class func viewUnpaidOrder(page: Int, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/fe/parentorder/list/unpaid"
        let parameters: [String: Any] = ["page": "\(page)", "userkey": Context.getUserKey()]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in complete(response)}
        return request
    }
    
    class func unpaidOrderCancelReason(_ success: @escaping ((_ value: [OrderCancelReason]) -> Void)) {
        let parameters: [String: Any] = ["keys": "UNPAID_ORDERCANCEL_REASON"]
        
        let request = RequestFactory.get(RESOURCE_PATH, parameters: parameters, appendUserKey: false)
        request.exResponseJSON(0, dnsRetryCount: 0, completionHandler: { response in
            if response.result.isSuccess {
                if let dicts = response.result.value as? [Dictionary<String, String>], dicts.count > 0, let v = dicts[0]["V"] {
                    if let reasons = Mapper<OrderCancelReason>().mapArray(JSONString: v) {
                        success(reasons)
                    }
                }
            }
        })
    }
    
    // MARK: - Order Cancel
    
    @discardableResult
    class func listOrderCancelReason(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/cancel/reason/list"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func createOrderCancel(orderKey: String, skuId: Int, qty: Int, orderCancelReasonId: Int, description: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/cancel/create"
        let parameters: [String: Any] = [
            "OrderKey": orderKey,
            "Skus": [["SkuId": skuId, "Qty": qty]],
            "OrderCancelReasonId": orderCancelReasonId,
            "Description": "\(description)"
        ]
        let request = RequestFactory.post(url, parameters: parameters, appendUserId: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func viewOrderCancel(orderCancelKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/cancel/view"
        let parameters: [String: Any] = ["OrderCancelKey": orderCancelKey]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    // MARK: - Order Return
    
    @discardableResult
    class func listOrderReturnReason(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/return/reason/list"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func viewOrderReturn(orderReturnKey: String, merchantId: Int? = nil, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/return/view"
        var parameters: [String: Any] = ["OrderReturnKey": orderReturnKey]
        var request: DataRequest
        if let merchantid = merchantId {
            parameters["merchantid"] = merchantid
            request = RequestFactory.get(url, parameters: parameters, appendUserKey: false)
        }
        else {
            request = RequestFactory.get(url, parameters: parameters)
        }
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    class func createOrderReturn(orderKey: String, merchantId: Int, skuId: Int, qty: Int, courierId: Int, orderReturnReasonId: Int, description: String, images: [Data]?, success : @escaping (DataResponse<Any>) -> Void, fail : @escaping (Error) -> Void){
        let url = ORDER_PATH + "/return/create"
        
        var parameters: [String: Any] = [
            "OrderKey": orderKey as Any,
            "UserKey": Context.getUserKey() as Any,
            "MerchantId": merchantId as Any,
            "SkuId": skuId as Any,
            "QtyReturned": qty as Any,
            "IsTaxInvoiceBack": 1 as Any,
            "OrderReturnReasonId": orderReturnReasonId as Any,
            "Description": "\(description)"
        ]
        
        if courierId > 0 {
            parameters["CourierId"] = courierId
        }
        
        RequestFactory.networkManager.upload(
            multipartFormData: { multipartFormData in
                var index = 0
                for imageData in images ?? []{
                    multipartFormData.append(imageData, withName: "Image", fileName: "orderReturnImage\(index).jpg", mimeType: "image/jpg")
                    index += 1
                }
                
                for (key, value) in parameters {
                    if let stringValue = value as? String {
                        multipartFormData.append(stringValue.data(using: String.Encoding.utf8)!, withName: key)
                    } else {
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
                        if let JSON = response.result.value {
                            Log.debug("JSON: \(JSON)")
                        }
                        
                        success(response)
                    }
                case .failure(let encodingError):
                    fail(encodingError)
                }
            }
        )
    }
    
    class func updateOrderReturn(orderReturnKey: String, orderKey: String, merchantId: Int, skuId: Int, qty: Int, courierId: Int, orderReturnReasonId: Int, orderDisputeReasonId: Int = 0, orderReturn: OrderReturn, description: String, images: [Data]?, success : @escaping (DataResponse<Any>) -> Void, fail : @escaping (Error) -> Void){
        let url = ORDER_PATH + "/return/update"
        
        var parameters: [String: Any] = [
            "OrderReturnKey": orderReturnKey as Any,
            "OrderKey": orderKey as Any,
            "UserKey": Context.getUserKey() as Any,
            "MerchantId": merchantId as Any,
            "SkuId": skuId as Any,
            "QtyReturned": qty as Any,
            "IsTaxInvoiceBack": orderReturn.isTaxInvoiceBack as Any,
            "OrderReturnReasonId": orderReturnReasonId,
            "OrderDisputeReasonId": orderDisputeReasonId,
            "LocationExternalCode" : orderReturn.locationExternalCode,
            "OrderReturnResponseId" : orderReturn.orderReturnResponseId,
            "OrderReturnConditionId" : orderReturn.orderReturnConditionId,
            "Description": "\(description)"
        ]
        
        if courierId > 0 {
            parameters["CourierId"] = courierId
        }
        
        RequestFactory.networkManager.upload(
            multipartFormData: { multipartFormData in
                var index = 0
                for imageData in images ?? []{
                    multipartFormData.append(imageData, withName: "Image", fileName: "orderReturnImage\(index).jpg", mimeType: "image/jpg")
                    index += 1
                }
                
                for (key, value) in parameters {
                    if let stringValue = value as? String {
                        multipartFormData.append(stringValue.data(using: String.Encoding.utf8)!, withName: key)
                    } else {
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
                        if let JSON = response.result.value {
                            Log.debug("JSON: \(JSON)")
                        }
                        
                        success(response)
                    }
                case .failure(let encodingError):
                    fail(encodingError)
                }
            }
        )
        
    }
    
    @discardableResult
    class func cancelOrderReturn(orderReturnKey: String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/return/cancel"
        let parameters: [String: Any] = ["OrderReturnKey": orderReturnKey]
        let request = RequestFactory.post(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    // MARK: - Order Dispute
    
    @discardableResult
    class func listOrderDisputeReason(_ completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/return/dispute/reason/list"
        let request = RequestFactory.get(url, appendUserKey: false)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    class func createOrderDispute(orderReturn: OrderReturn?, skuId: Int, qty: Int, orderDisputeReasonId: Int, description: String, images: [Data]? , success: @escaping (DataResponse<Any>) -> Void, fail : @escaping (Error) -> Void){
        var url = ORDER_PATH
        
        if let orderReturnStatus = orderReturn?.orderReturnStatus {
            switch orderReturnStatus {
            case .returnRejected:
                url = url + "/return/returndispute"
            case .returnRequestRejected:
                url = url + "/return/requestdispute"
            default:
                break
            }
        }
        
        let parameters: [String: Any] = [
            "OrderReturnKey": orderReturn?.orderReturnKey ?? "",
            "Skus": [["SkuId": skuId, "Qty": qty]],
            "UserKey": Context.getUserKey(),
            "OrderDisputeReasonId": orderDisputeReasonId,
            "Description": "\(description)"
        ]
        
        RequestFactory.networkManager.upload(
            multipartFormData: { multipartFormData in
                var index = 0
                for imageData in images ?? []{
                    multipartFormData.append(imageData, withName: "Image", fileName: "orderReturnImage\(index).jpg", mimeType: "image/jpg")
                    index += 1
                }
                
                for (key, value) in parameters {
                    if let stringValue = value as? String {
                        multipartFormData.append(stringValue.data(using: String.Encoding.utf8)!, withName: key)
                    } else {
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
                    Log.debug("Success")
                    
                    upload.responseJSON { response in
                        if let JSON = response.result.value {
                            Log.debug("JSON: \(JSON)")
                        }
                        
                        success(response)
                    }
                case .failure(let encodingError):
                    fail(encodingError)
                }
            }
        )
        
    }
    
    // MARK: - After Sales
    
    @discardableResult
    class func listAfterSalesReasons(afterSalesType: Constants.OMSAfterSalesType = .cancel, completion complete: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        switch afterSalesType {
        case .cancel:
            return listOrderCancelReason(complete)
        case .`return`:
            return listOrderReturnReason(complete)
        case .dispute:
            return listOrderDisputeReason(complete)
        }
    }
    
    @discardableResult
    class func listAfterSalesHistory(orderKey: String, afterSalesHistoryType: AfterSalesHistoryType, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/history/list"
        let parameters: [String: Any] = [
            "OrderKey": orderKey,
            "EntityTypeId": afterSalesHistoryType.rawValue
        ]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    // MARK: - General
    
    class func getOrderStatusIds(viewMode: Constants.OmsViewMode) -> String {
        var orderStatusList: [Order.OrderStatus] = []
        
        switch viewMode {
        case .all:
            orderStatusList.append(.closed)
            orderStatusList.append(.confirmed)
            orderStatusList.append(.paid)
            orderStatusList.append(.shipped)
            orderStatusList.append(.received)
            orderStatusList.append(.cancelled)
        case .toBeShipped:
            orderStatusList.append(.confirmed)
            orderStatusList.append(.paid)
        case .toBeReceived:
            orderStatusList.append(.shipped)
        case .toBeRated:
            orderStatusList.append(.received)
        case .afterSales:
            orderStatusList.append(.confirmed)
            orderStatusList.append(.paid)
            orderStatusList.append(.shipped)
            orderStatusList.append(.received)
            orderStatusList.append(.cancelled)
            orderStatusList.append(.closed)
        default:
            break
        }
        
        orderStatusList.append(.partialShipped)
        
        return orderStatusList.map{ String($0.rawValue) }.joined(separator: ",")
    }
    
    @discardableResult
    class func viewMeta(_ parentOrderKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        let url = ORDER_PATH + "/parent/viewmeta"
        let parameters: [String: Any] = ["ParentOrderKey": "\(parentOrderKey)"]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func viewMetaOrder(_ parentOrderKey : String,  completion: @escaping (DataResponse<Any>) -> Void) -> Request {
        let url = ORDER_PATH + "/parent/view"
        let parameters: [String: AnyObject] = ["ParentOrderKey": "\(parentOrderKey)" as AnyObject]
        let request = RequestFactory.get(url, parameters: parameters)
        request.exResponseJSON{response in completion(response)}
        return request
    }

    @discardableResult
    class func confirmOrder(_ parentOrderKey : String, completion: @escaping (DataResponse<Any>) -> Void) -> Request {
        let url = ORDER_PATH + "/parent/confirm"
        let parameters: [String: Any] = ["ParentOrderKey": "\(parentOrderKey)"]
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: true)
        request.exResponseJSON{response in completion(response)}
        return request
    }
    
    @discardableResult
    class func expireOrder(_ parentOrderKey : String, reason: String?, completion: @escaping (DataResponse<Any>) -> Void) -> Request {
        let url = ORDER_PATH + "/parent/expire"
        var parameters: [String: Any] = ["ParentOrderKey": "\(parentOrderKey)"]
        if let reason = reason {
            parameters["Reason"] = reason
        }
        let request = RequestFactory.post(url, parameters: parameters, appendUserKey: true)
        request.exResponseJSON(0, dnsRetryCount: 0, completionHandler: { response in
            completion(response)
        })
        return request
    }
    
}
