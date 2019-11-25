//
//  AliPayManager.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 1/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper

class AliPayManager {
    
    class func pay(_ viewController: UIViewController, parentOrder: ParentOrder, callback: @escaping (Bool, String)->()) {
        let alipayCreateSign = AlipayCreateSign()
        
        if parentOrder.isCrossBorder > 0 {
            alipayCreateSign.subject = "MM Global Payment on iOS"
            alipayCreateSign.body = "iOS Global Payment String"
            alipayCreateSign.rmbFee = "\(parentOrder.grandTotal)"
            alipayCreateSign.splitFundInfo = "\(parentOrder.domesticTotal)"
        } else {
            alipayCreateSign.subject = "MM Payment on iOS"
            alipayCreateSign.body = "iOS Payment String"
            alipayCreateSign.totalFee = "\(parentOrder.grandTotal)"
        }
        
        alipayCreateSign.outTradeNo = parentOrder.parentOrderKey
        
        MmAlipayService.createSign(alipayCreateSign) { (response) in
            var isShowCreateSignDefaultError = false
            
            if response.result.isSuccess {
                if response.response?.statusCode == 200 {
                    let createSignResponse = Mapper<CreateSignResponse>().map(JSONObject: response.result.value)
                    
                    if let paymentString = createSignResponse?.paymentString {
                        
                        AlipaySDK.defaultService().payOrder(paymentString, fromScheme: "alisdkmm") { (resultDic) -> Void in
                            var isShowPayOrderDefaultError = false
                            
                            Log.debug("Finish AliPay payment")
                            
                            if let resultDic = resultDic as? [String : Any], let result = resultDic["result"] as? String, let resultStatus = resultDic["resultStatus"] as? String {
                                let alipayVerifyRequest = AlipayVerifyRequest()
                                alipayVerifyRequest.result = result
                                
                                if resultStatus == "6001" {
                                    callback(false, "") // To detect when user cancelled AliPay
                                }
                                else if resultStatus != "6001" {
                                    MmAlipayService.verify(alipayVerifyRequest) { (response) in
                                        var isShowVerifyDefaultError = false
                                        
                                        if response.result.isSuccess {
                                            if response.response?.statusCode == 200 {
                                                if let verifyResult = response.result.value as? Int {
                                                    if verifyResult == 1 {
                                                        switch resultStatus {
                                                        case "9000":
                                                            callback(true, "")
                                                            TalkingDataOnPlaceOrder(parentOrder)
                                                        case "8000":
                                                            callback(false, "正在处理中")
                                                        case "4000":
                                                            callback(false, "订单支付失败")
                                                        case "5000":
                                                            callback(false, String.localize("MSG_ERR_PARENT_ORDER_IS_NOT_INITIATED"))
                                                        case "6001":
                                                            callback(false, "用户中途取消")
                                                        case "6002":
                                                            callback(false, "网络连接出错")
                                                        default:
                                                            isShowVerifyDefaultError = true
                                                        }
                                                    } else {
                                                        isShowVerifyDefaultError = true
                                                        ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: Failed to verify result")
                                                        Log.debug("Failed to verify result")
                                                    }
                                                } else {
                                                    isShowVerifyDefaultError = true
                                                    ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: Invalid verify result")
                                                    Log.debug("Invalid verify result")
                                                }
                                            } else {
                                                isShowVerifyDefaultError = true
                                                ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: MmAlipayService.verify() != 200")
                                                Log.debug("MmAlipayService.verify() != 200")
                                            }
                                        } else {
                                            isShowVerifyDefaultError = true
                                            ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: MmAlipayService.verify() Failed")
                                            Log.debug("MmAlipayService.verify() Failed")
                                        }
                                        
                                        if isShowVerifyDefaultError {
//                                            AliPayManager.showErrorMessage(onViewController: viewController, parentOrder: parentOrder)
                                            
                                            ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: MSG_ERR_ALIPAY_SIGN_VER_ERR", parameters: ["OrderKey" : parentOrder.parentOrderKey, "Payload" : result])
                                            callback(true, "")
                                        }
                                    }
                                }
                            } else {
                                isShowPayOrderDefaultError = true
                                ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: Failed to parse result")
                                Log.debug("Failed to parse result")
                            }
                            
                            if isShowPayOrderDefaultError {
//                                AliPayManager.showErrorMessage(onViewController: viewController, parentOrder: parentOrder)
                                
                                ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: MSG_ERR_ALIPAY_SIGN_VER_ERR", parameters: ["OrderKey" : parentOrder.parentOrderKey])
                                callback(true, "")
                            }
                        }
                    } else {
                        isShowCreateSignDefaultError = true
                        ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: Payment string is empty")
                        Log.debug("Payment string is empty")
                    }
                } else {
                    isShowCreateSignDefaultError = true
                    ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: MmAlipayService.createSign() != 200")
                    Log.debug("MmAlipayService.createSign() != 200")
                }
            } else {
                isShowCreateSignDefaultError = true
                ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: MmAlipayService.createSign() Failed")
                Log.debug("MmAlipayService.createSign() Failed")
            }
             
            if isShowCreateSignDefaultError {
//                AliPayManager.showErrorMessage(onViewController: viewController, parentOrder: parentOrder)
                
                ErrorLogManager.sharedManager.recordNonFatalError(withMessage: "Alipay: MSG_ERR_ALIPAY_SIGN_VER_ERR", parameters: ["OrderKey" : parentOrder.parentOrderKey])
                callback(false, "") //force return failure to callback if isShowCreateSignDefaultError
            }
        }
    }
    
    class func TalkingDataOnPlaceOrder(_ parentOrder: ParentOrder) {
        TrackManager.recordPay(orderId: parentOrder.parentOrderKey, payOrderAmount: parentOrder.grandTotal, orderAmount: parentOrder.GMV())
    }

    class func showErrorMessage(onViewController viewController: UIViewController, parentOrder: ParentOrder) {
        let alertMessage = String.localize("MSG_ERR_ALIPAY_SIGN_VER_ERR").replacingOccurrences(of: "{0}", with: "\(parentOrder.parentOrderKey)")
        
        Alert.alertWithSingleButton(viewController, title: "", message: alertMessage, buttonString: String.localize("LB_CA_OMS_CONTACT_CS"), actionComplete: {
            let myRole: UserRole = UserRole(userKey: Context.getUserKey())
            
            WebSocketManager.sharedInstance().sendMessage(
                IMConvStartToCSMessage(
                    userList: [myRole],
                    queue: .General,
                    senderMerchantId: myRole.merchantId,
                    merchantId: Constants.MMMerchantId
                ),
                completion: { (ack) in
                    if let convKey = ack.data {
                        WebSocketManager.sharedInstance().sendMessage(
                            IMTextMessage(text: alertMessage, convKey: convKey, myUserRole: myRole),
                            completion: { (ack) in
                                let userChatViewController = UserChatViewController(convKey: convKey)
                                
                                viewController.navigationController?.isNavigationBarHidden = false
                                viewController.navigationController?.pushViewController(userChatViewController, animated: true)
                            }
                        )
                        
                    } else {
                        Log.debug("IM convKey not found")
                    }
                }
            )
        })
    }
    
}
