//
//  CheckoutHandler.swift
//  merchant-ios
//
//  Created by Tony Fung on 6/7/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Alamofire

class CheckoutHandler {

    private weak var cartViewController: MmCartViewController?
    private weak var unpaidViewController: OrderBaseViewController?
    private var pollTimer: Timer?
    private var retryPollingCount = 0
    private var processingOrder: ParentOrder?
    private var confirmedOrder: ParentOrder?
    private var dismissHandler: ((ParentOrder?) -> ())?
    
    init(cartController: MmCartViewController, dismiss: ((ParentOrder?) -> ())?) {
        self.cartViewController = cartController
        dismissHandler = dismiss
    }
    
    init(unpaidViewController: OrderBaseViewController, dismiss: ((ParentOrder?) -> ())?) {
        self.unpaidViewController = unpaidViewController
        dismissHandler = dismiss
    }
    
    func processCreateOrder(_ skus: [Dictionary<String,Any>], orders: [Dictionary<String,Any>], mmCoupon: Coupon? = nil, addressKey: String, isCart: Bool, isFlashSale: Bool = false, paymentMethod: Constants.PaymentMethod = .alipay, failBlock: ((Error, MmCartViewController) -> ())? = nil) {
        if LoginManager.getLoginState() == .validUser {
            if skus.count == 0 {
                return
            }
            
            guard addressKey != "" else {
                cartViewController?.showError(String.localize("MSG_ERR_CA_SWIPE2PAY_ADDR"), animated: true)
                return
            }
            
            if let cvc = cartViewController{
                LoadingOverlay.shared.showOverlay(cvc)
            }
            
            firstly {
                return self.createOrder(addressKey, skus: skus, orders: orders, mmCoupon: mmCoupon, isCart: isCart, isFlashSale:isFlashSale)
                }.then { order -> Void in
                    for order in orders {
                        if let merchantId = order["MerchantId"] as? Int {
                            CouponManager.shareManager().invalidate(wallet: merchantId)
                        }
                    }
                    if let _ = mmCoupon {
                        CouponManager.shareManager().invalidate(wallet: Constants.MMMerchantId)
                    }
                    CacheManager.sharedManager.resetCouponFetchingTime()
                    
                    if isCart {
                        CacheManager.sharedManager.refreshCart()
                    }
                    
                    self.processingOrder = order
                    
                    if order.isCrossBorder > 0 && !order.isUserIdentificationExists {
                        let viewController = IDCardCollectionPageViewController(updateCardAction: .swipeToPay)
                        viewController.order = order
                        viewController.paymentMethod = paymentMethod
                        
                        viewController.callBackAction = {
                            //we go back this function to...
                            self.continuePayment(paymentMethod, completion: { (success, error) in
                                if let error = error, let cartViewController = self.cartViewController, !success{
                                    failBlock?(error, cartViewController)
                                }
                            })
                        }
                        
                        self.cartViewController?.navigationController?.isNavigationBarHidden = false
                        self.cartViewController?.navigationController?.pushViewController(viewController, animated: true)
                    } else {
                        self.continuePayment(paymentMethod, completion: { (success, error) in
                            if let error = error, let cartViewController = self.cartViewController, !success{
                                failBlock?(error, cartViewController)
                            }
                        })
                    }
                }.always {
                    LoadingOverlay.shared.hideOverlayView()
                    //self.cartViewController?.stopLoading()
                }.catch { error in
                    Log.error("error" as Any)
                    if let cartViewController = self.cartViewController{
                        failBlock?(error, cartViewController)
                    }
            }
        } else {
            LoginManager.goToLogin {
                self.processCreateOrder(skus, orders: orders, mmCoupon: mmCoupon, addressKey: addressKey, isCart: isCart, isFlashSale: isFlashSale, paymentMethod: paymentMethod, failBlock: failBlock)
            }
        }
    }
    
    private func continuePayment(_ paymentMethod: Constants.PaymentMethod, completion: ((_ success: Bool, _ error: NSError?) -> ())?) {
        if let order = self.processingOrder {
            if Constants.IsDeveloperMode || paymentMethod == .cod {
                firstly {
                    return self.confirmOrderStatus(order)
                }.then { _ -> Void in
                    if let cvc = self.cartViewController{
                        cvc.startPaymentProcess = false
                    }

                    self.confirmedOrder = self.processingOrder
                    self.dismissHandler?(self.confirmedOrder)
                    self.dismissHandler = nil
                    completion?(true, nil)
                }
            } else if let cartViewController = self.cartViewController, paymentMethod == .alipay {
                AliPayManager.pay(cartViewController, parentOrder: order, callback: { [weak self] (success, error) in
                    if let strongSelf = self{
                        if success {
                            strongSelf.pollTimer = Timer.scheduledTimer(timeInterval: Constants.Duration.AliPay, target: strongSelf, selector: #selector(strongSelf.pollOrderStatus), userInfo: nil, repeats: true)
                            strongSelf.retryPollingCount = 0
                            //strongSelf.cartViewController?.showLoading()
                            
                            if let cvc = strongSelf.cartViewController{
                                cvc.startPaymentProcess = false
                                LoadingOverlay.shared.showOverlay(cvc)
                            }
                        } else {
                            if let cartViewController = strongSelf.cartViewController, !error.isEmpty{
                                Alert.alert(cartViewController, title: error, message: error)
                            }
                        }
                        
                        let error = NSError(domain: error, code: 0, userInfo: nil)
                        completion?(success, error)
                        
                    }else {
                        completion?(false, nil)
                        ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                    }
                })
            }
        }
    }
    
    func processUnpaidPayment(_ parentOrder: ParentOrder, completion: ((_ success: Bool, _ error: NSError?) -> ())?) {
        self.processingOrder = parentOrder
        
        if let unpaidViewController = self.unpaidViewController{
            AliPayManager.pay(unpaidViewController, parentOrder: parentOrder, callback: { [weak self] (success, error) in
                if let strongSelf = self{
                    if success {
                        strongSelf.pollTimer = Timer.scheduledTimer(timeInterval: Constants.Duration.AliPay, target: strongSelf, selector: #selector(strongSelf.pollOrderStatus), userInfo: nil, repeats: true)
                        strongSelf.retryPollingCount = 0
                        if let cvc = strongSelf.unpaidViewController{
                            LoadingOverlay.shared.showOverlay(cvc)
                            
                        }
                        //strongSelf.cartViewController?.showLoading()
                    } else {
                        if let cartViewController = strongSelf.unpaidViewController, !error.isEmpty{
                            Alert.alert(cartViewController, title: error, message: error)
                        }
                    }
                    
                    let err = NSError(domain: error, code: 0, userInfo: nil)
                    completion?(success, err)
                    
                }else {
                    completion?(false, nil)
                    ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
                }
                })
        }
        
    }
    
    @objc func enableButton(_ sender: Timer){
        if let cvc = self.cartViewController{
            cvc.confirmButton.isUserInteractionEnabled = true
            cvc.confirmButton.formatPrimary()
        }
    }
    
    @objc func pollOrderStatus() {
        retryPollingCount += 1
        
        if retryPollingCount > 5 {
            retryPollingCount = 0
            
            if let _ = cartViewController{
                LoadingOverlay.shared.hideOverlayView()
                //cartViewController.stopLoading()
                if let checkoutViewController = self.cartViewController as? FCheckoutViewController{
                    checkoutViewController.enableAllButton()
                }
            }else if let _ = unpaidViewController{
                LoadingOverlay.shared.hideOverlayView()
            }
            
            if let timer = self.pollTimer {
                timer.invalidate()
                self.pollTimer = nil
            }
        }
        
        if let order = self.processingOrder {
            firstly {
                return self.getOrderStatus(order)
            }.then { order -> Void in
                self.processingOrder = order
                self.confirmedOrder = order
                
                if order.parentOrderStatusId == 2 {
                    if let timer = self.pollTimer {
                        CheckoutService.defaultService.saveSuccessParentOrderKey(withParentOrderKey: order.parentOrderKey)
                        timer.invalidate()
                        self.pollTimer = nil
                        self.dismissHandler?(self.confirmedOrder)
                        self.dismissHandler = nil
                        LoadingOverlay.shared.hideOverlayView()
                        //self.cartViewController?.stopLoading()
                        if let checkoutViewController = self.cartViewController as? FCheckoutViewController{
                            checkoutViewController.enableAllButton()
                        }
                    }
                }
            }.always {
            }
            
        }
    }
    
    // MARK: Promise wrapper
    
    func checkOrderService(_ userAddressKey: String, skus: [Dictionary<String,Any>], orders: [Dictionary<String,Any>], coupon: Coupon? = nil) -> Promise<ParentOrder> {
        return Promise{ fulfill, reject in
            OrderService.checkOrder(userAddressKey, skus: skus, orders: orders, coupon: coupon, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        print(response.description)
                        if response.response?.statusCode == 200 {
                            if let order = Mapper<ParentOrder>().map(JSONObject: response.result.value) {
                                fulfill(order)
                            }
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let errorInfo = strongSelf.getErrorInfo(response)
                            let error = NSError(domain: "", code: statusCode, userInfo: errorInfo)
                            
                            reject(error)
                        }
                    } else {
                        var error : NSError?
                        if let err = response.result.error as NSError? {
                            error = err
                        } else {
                            error = NSError(domain: "", code: 0, userInfo: ["errorCode": "LB_ERROR"])
                        }
                        reject(error!)
                    }
                }
            })
        }
    }
    
    func checkStockService(_ skus: [Dictionary<String,Any>], orders: [Dictionary<String,Any>], coupon: Coupon? = nil,isFlashSale: Bool = false) -> Promise<ParentOrder> {
        return Promise{ fulfill, reject in
            OrderService.checkStock(skus, orders: orders, coupon: coupon, isFlashSale:isFlashSale, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let order = Mapper<ParentOrder>().map(JSONObject: response.result.value) {
                                fulfill(order)
                            }
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let errorInfo = strongSelf.getErrorInfo(response)
                            let error = NSError(domain: "", code: statusCode, userInfo: errorInfo)
                            
                            reject(error)
                        }
                    } else {
                        var error: Error?
                        
                        if response.result.error != nil && (response.result.error as NSError?)?.userInfo != nil {
                            error = response.result.error
                        } else {
                            error = NSError(domain: "", code: 0, userInfo: ["errorCode": "LB_ERROR"])
                        }
                        reject(error!)
                    }
                }
            })
        }
    }
    
    private func confirmOrderStatus(_ order: ParentOrder) -> Promise<Any> {
        return Promise{ fulfill, reject in
            OrderService.confirmOrder(order.parentOrderKey) { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        fulfill("OK")
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
    private func getOrderStatus(_ order: ParentOrder) -> Promise<ParentOrder> {
        return Promise{ fulfill, reject in
            OrderService.viewMeta(order.parentOrderKey) { (response) in
                if response.result.isSuccess {
                    if response.response?.statusCode == 200 {
                        if let order = Mapper<ParentOrder>().map(JSONObject: response.result.value) {
                            fulfill(order)
                        }
                    } else {
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        let error = NSError(domain: "", code: statusCode, userInfo: nil)
                        reject(error)
                    }
                } else {
                    reject(response.result.error!)
                }
            }
        }
    }
    
    
    private func createOrder(_ userAddressKey: String, skus: [Dictionary<String,Any>], orders: [Dictionary<String,Any>], mmCoupon: Coupon? = nil, isCart: Bool, isFlashSale:Bool) -> Promise<ParentOrder> {
        return Promise{ fulfill, reject in
            OrderService.createOrder(userAddressKey, skus: skus, orders: orders, coupon: mmCoupon, isCart: isCart, isFlashSale:isFlashSale, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let order = Mapper<ParentOrder>().map(JSONObject: response.result.value) {
                                NotificationCenter.default.post(name: Constants.Notification.orderCreatedSucceed, object: nil)
                                fulfill(order)
                                TrackManager.recordGMV(orderId: order.parentOrderKey, payOrderAmount: order.grandTotal, orderAmount: order.GMV())
                            }
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let errorInfo = strongSelf.getErrorInfo(response)
                            let error = NSError(domain: "", code: statusCode, userInfo: errorInfo)

                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.cartViewController?.showErrorAlert(String.localize("MSG_ERR_NETWORK_FAIL"))
                    }
                }
            })
        }
    }
    
    private func getErrorInfo(_ response: DataResponse<Any>) -> [String: String] {
        var errorInfo = [String: String]()
        
        if let resp = Mapper<ApiResponse>().map(JSONObject: response.value) {
            if let appCode = resp.appCode {
                errorInfo["AppCode"] = appCode
            }
            else {
                errorInfo["AppCode"] = "LB_ERROR"
            }
            
            if let message = resp.message {
                errorInfo["Message"] = message
            }
        }
        
        return errorInfo
    }
    
    func getConfirmedOrder() -> ParentOrder? {
        return confirmedOrder
    }
    
    
}


