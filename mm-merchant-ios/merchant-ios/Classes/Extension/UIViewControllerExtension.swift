//
//  UIViewControllerExtension.swift
//  merchant-ios
//
//  Created by Hang Yuen on 5/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire
import UIAlertController_Blocks
import MBProgressHUD

enum MMAlertLevel : Int {
    case normal = 0
    case error = 100
    case unauthorized = 105
    case upgrade = 110
}

extension UIViewController {
    
    func showSuccAlert(_ message: String) {
        UIAlertController.showAlert(in: self, withTitle: "", message: message, cancelButtonTitle: String.localize("LB_OK"), destructiveButtonTitle: nil, otherButtonTitles: nil) { (controller , action, buttonIndex) -> Void in
        }
    }
    
    func idleAlertShow(_ message: String, level:MMAlertLevel = MMAlertLevel.error) -> Bool {
        var notShow = false
        if let alert = self as? UIAlertController,let tag = alert.ssn_tag("ALERT_TYPE") as? MMAlertLevel,tag.rawValue >= level.rawValue {
            notShow = true
        } else if let alert = self.presentedViewController as? UIAlertController,let tag = alert.ssn_tag("ALERT_TYPE") as? MMAlertLevel,tag.rawValue >= level.rawValue {
            notShow = true
        }
        if notShow {
            print("界面有相关提示，不必反复提示：\"\(message)\"")
        }
        return !notShow
    }
    
    func showErrorAlert(_ message: String) {
        if idleAlertShow(message) {
            let alert = UIAlertController.showAlert(in: self, withTitle: "", message: message, cancelButtonTitle: String.localize("LB_OK"), destructiveButtonTitle: nil, otherButtonTitles: nil) { (controller , action, buttonIndex) -> Void in
            }
            alert.ssn_setTag("ALERT_TYPE", tag: MMAlertLevel.error)
        }
    }
    
    func showNetWorkErrorAlert(_ error: Error?) {
        let message = Utils.formatErrorMessage(
            String.localize("MSG_ERR_NETWORK_FAIL"),
            error: error
        )
        
        if idleAlertShow(message) {
            let alert = UIAlertController.showAlert(in: self, withTitle: "", message: message, cancelButtonTitle: String.localize("LB_OK"), destructiveButtonTitle: nil, otherButtonTitles: nil) { (controller , action, buttonIndex) -> Void in
            }
            alert.ssn_setTag("ALERT_TYPE", tag: MMAlertLevel.error)
        }
    }
    
    func showFailPopupWithText(_ text: String) {
        if let view = self.navigationController?.view ?? self.view {
            dispatch_async_safely_to_main_queue({
                MBProgressHUD.hideAllHUDs(for: view, animated: false)
                if let hud = MBProgressHUD.showAdded(to: view, animated: true) {
                    hud.isUserInteractionEnabled = false
                    hud.mode = .customView
                    hud.opacity = 0.7
                    hud.labelText = text
                    hud.margin = 10
                    hud.hide(true, afterDelay: 1.5)
                }
            })
        }
    }
    
    func showUnauthorizedAlert() {
        let msg = String.localize("MSG_ERR_CA_INACTIVATED_LOGOUT") //登出
        if idleAlertShow(msg, level:MMAlertLevel.unauthorized) {
            let alert = UIAlertController.showAlert(in: self, withTitle: "", message: msg, cancelButtonTitle: String.localize("LB_OK"), destructiveButtonTitle: nil, otherButtonTitles: nil) { (controller , action, buttonIndex) -> Void in
                LoginManager.logout()
                LoginManager.goToLogin()
            }
            alert.ssn_setTag("ALERT_TYPE", tag: MMAlertLevel.unauthorized)
        }
    }
    
    @discardableResult
    func showUpgradeAlert(forceUpgrade: Bool, appStoreLink: String = Constants.AppStoreLink) -> Bool {
        if !idleAlertShow(String.localize("LB_CA_APP_UPDATE_2"), level:MMAlertLevel.upgrade) {
            return true
        }
        
        let alertController = UIAlertController(title: String.localize("LB_CA_APP_UPDATE_1"), message: String.localize("LB_CA_APP_UPDATE_2"), preferredStyle: .alert)
        alertController.ssn_setTag("ALERT_TYPE", tag: MMAlertLevel.upgrade)
        
        alertController.view.tintColor = UIColor.alertTintColor()
        if !forceUpgrade {
            alertController.addAction(UIAlertAction(title: String.localize("LB_CANCEL"), style: .default, handler: nil))
        }
        
        alertController.addAction(UIAlertAction(title: String.localize("LB_OK"), style: .default, handler: { (action) -> Void in
            UIApplication.shared.openURL(URL(string: appStoreLink)!)
        }))
        
        self.present(alertController, animated: true, completion: nil)
        
        return true
    }
    
    // handle the api response object
    func handleApiResponseError(apiResponse: ApiResponse, statusCode: Int,  shouldShowErrorDialog: Bool = true, reject : ((Error) -> Void)? = nil) {
        
        if let appCode = apiResponse.appCode {
            if appCode == "MSG_ERR_USER_UNAUTHORIZED" {
                showUnauthorizedAlert()
            }else {
                let skipErrors = ["MSG_ERR_WISHLIST_NOT_FOUND",
                                  "MSG_ERR_SEARCH_FAIL",
                                  "MSG_ERR_CART_NOT_FOUND",
                                  "MSG_ERR_USER_ADDRESS_EMPTY", "MSG_ERR_USER_NOT_EXISTS","MSG_ERR_CS_INVITE_CODE_INVALID","MSG_ERR_CA_DUP_USERNAME","MSG_ERR_USER_AUTHENTICATION_FAIL", "MSG_ERR_CA_COUPON_CODE_EXCEED_LIMIT"]
                if !skipErrors.contains(appCode) {
                    let msg = String.localize(appCode)
                    if shouldShowErrorDialog {
                        self.showErrorAlert(msg)
                    }
                    
                    if let reject = reject {
                        reject(NSError(domain: "", code: statusCode, userInfo: ["Error" : (String.localize(apiResponse.appCode))]))
                    }
                }
            }
        }
    }
    
    func handleApiResponseError(_ response :  DataResponse<Any>, shouldShowErrorDialog: Bool = true, reject : ((Error) -> Void)? = nil) {
        if let resp = Mapper<ApiResponse>().map(JSONObject: response.result.value){
            self.handleApiResponseError(apiResponse: resp, statusCode: (response.response?.statusCode)!, shouldShowErrorDialog: shouldShowErrorDialog, reject: reject)
        } else {
            self.showErrorAlert(
                Utils.formatErrorMessage(
                    String.localize("LB_ERROR"),
                    error: response.result.error
                )
            )
        }
    }
    
    func handleLoginApiResponseError(_ JSON : Any?) {
        if let resp = Mapper<ApiResponse>().map(JSONObject: JSON){
            if let appCode = resp.appCode  {
                var msg: String! = String.localize(appCode)
                if let range : Range<String.Index> = msg.range(of: "{0}") {
                    if let loginAttempts = resp.loginAttempts {
                        msg = msg.replacingCharacters(in: range, with:"\(Constants.Value.MaxLoginAttempts - loginAttempts)")
                    }
                }
                self.showErrorAlert(msg)
            } else {
                self.showErrorAlert(String.localize("LB_ERROR"))
            }
        }
    }
    
    /// 获取tabbar
    var mm_tabbarController: MMTabBarController? {
        if let rootVC = UIApplication.shared.delegate!.window!!.rootViewController {
            if let tabbarController = rootVC as? MMTabBarController {
                return tabbarController
            }
        }
        return nil
    }
    
    /// 打开侧滑界面
    @objc public func showLeftMenuView() {
        if LoginManager.getLoginState() == .validUser {
            self.mm_tabbarController?.showMenuController()
        } else {
            LoginManager.goToLogin {
                self.showLeftMenuView()
            }
        }
    }
}
