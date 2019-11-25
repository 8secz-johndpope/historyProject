//
//  RequestExtension.swift
//  merchant-ios
//
//  Created by Hang Yuen on 3/11/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import MBProgressHUD

extension DataRequest {
    
    fileprivate struct AssociatedKeys {
        static var shouldShowErrorDialogKey = "shouldShowErrorDialogKey"
    }
    
    var shouldShowErrorDialog: Bool {
        get {
            if let valueShowDialog = objc_getAssociatedObject(self, &AssociatedKeys.shouldShowErrorDialogKey) as? String {
                return valueShowDialog == "true"
            }
            
            return true
        }
        set {
            
            var shouldShowErrorDialog = "true"
            if !newValue {
                shouldShowErrorDialog = "false"
            }
            objc_setAssociatedObject(self, &AssociatedKeys.shouldShowErrorDialogKey, shouldShowErrorDialog, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    
    class func rebuildRequest(_ request: Alamofire.DataRequest) -> DataRequest {
        guard let originalURLRequest = request.request else { return request }
        return RequestFactory.networkManager.request(originalURLRequest)
    }
    
    @discardableResult
    public func exResponseJSON(_ retryCount: Int = /*Constants.ErrorHandling.RetryCount*/3, dnsRetryCount : Int = /*Constants.ErrorHandling.DNSRetryCount*/3, options: JSONSerialization.ReadingOptions = .allowFragments, completionHandler: @escaping (DataResponse<Any>) -> Void) -> DataRequest {
        
        var req = self
        
        if dnsRetryCount != Constants.ErrorHandling.DNSRetryCount || retryCount != Constants.ErrorHandling.RetryCount {
            req = DataRequest.rebuildRequest(req)
        }
        
        req = req.response(
            responseSerializer: DataRequest.jsonResponseSerializer(options: options),
            completionHandler: { (response) in
                let strongSelf = self
                
                if let api = response.request?.url {
                    Log.debug("Requesting API : \(api) \n \(response.timeline)")
                }
                
                if let headers = response.response?.allHeaderFields {
                    if let forceUpgrade = headers["ForceUpgrade"] as? String, forceUpgrade == "true" {
                        if let serverAppStoreLink = headers["AppURL"] as? String {
                            strongSelf.showUpgradePrompt(forceUpgrade: true, appStoreLink: serverAppStoreLink)
                        } else {
                            strongSelf.showUpgradePrompt(forceUpgrade: true)
                        }
                    } else if let appLatestVersion = headers["AppLatestVersion"] as? String {
                        var textAppVersions = Constants.AppVersion.split(whereSeparator: {$0 == "."}).map(String.init)
                        var textAppLatestVersions = appLatestVersion.split(whereSeparator: {$0 == "."}).map(String.init)
                        
                        var appVersions = [0, 0, 0]
                        var appLatestVersions = [0, 0, 0]
                        
                        for i in 0..<min(textAppVersions.count, appVersions.count) {
                            appVersions[i] = Int(textAppVersions[i]) ?? 0
                        }
                        
                        for i in 0..<min(textAppLatestVersions.count, appLatestVersions.count) {
                            appLatestVersions[i] = Int(textAppLatestVersions[i]) ?? 0
                        }
                        
                        var recommendUpgrade = false
                        
                        recommendUpgrade = appVersions.lexicographicallyPrecedes(appLatestVersions)
                        
                        if recommendUpgrade {
                            
                            if let lastPromptTime = Context.getLastAppUpgradeAlertPromptTime(), lastPromptTime.timeIntervalSinceNow < TimeInterval(-86400) {
                                
                                var alertIsShown = false
                                var forceUpgrade = false
                                
                                if let force = headers["ForceUpgrade"] as? String, force == "true" {
                                    forceUpgrade = true
                                }
                                
                                if let serverAppStoreLink = headers["AppURL"] as? String {
                                    alertIsShown = strongSelf.showUpgradePrompt(forceUpgrade: forceUpgrade, appStoreLink: serverAppStoreLink)
                                } else {
                                    alertIsShown = strongSelf.showUpgradePrompt(forceUpgrade: forceUpgrade)
                                }
                                
                                if alertIsShown {
                                    Context.setLastAppUpgradeAlertPromptTime(Date())
                                }
                            }
                        }
                    }
                }
                
                let handle50X = { () -> Bool in
                    
                    if (response.response?.statusCode == 502 || response.response?.statusCode == 503 || response.response?.statusCode == 504 || response.response?.statusCode == 505) && retryCount > 0 {
                        
                        //retry for 50X always 3 times to avoid too many attempts
                        
                        let nextCount = min(retryCount, 3) - 1
                        
                        var waiting = 2.000
                        
                        if nextCount > 1 {
                            // 2s - 10s
                            waiting = Double(Int(arc4random()) % 8000 + 3000) / 1000
                        } else if nextCount > 0 {
                            // 10s - 20s
                            waiting = Double(Int(arc4random()) % 10000 + 11000) / 1000
                        } else {
                            // 10s - 30s
                            waiting = Double(Int(arc4random()) % 20000 + 11000) / 1000
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + waiting) {
                            strongSelf.exResponseJSON(nextCount, completionHandler: completionHandler)
                        }
                        
                        return true
                        
                    }
                    
                    return false
                }
                
                if response.result.isSuccess {
                    
                    if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
                        MBProgressHUD.hideAllHUDs(for: window, animated: true)
                    }
                    
                    let storefroneHandler = {
                        strongSelf.getTopViewController()?.handleApiResponseError(response, shouldShowErrorDialog: strongSelf.shouldShowErrorDialog)
                        completionHandler(response)
                    }
                    
                    if handle50X() {
                        return
                    }
                    
                    if response.response?.statusCode == 401 {
                        storefroneHandler()
                    } else if response.response?.statusCode != 200 {
                        storefroneHandler()
                    } else {    
                        completionHandler(response)
                    }
                    
                } else {
                    
                    if handle50X() {
                        return
                    }
                    
                    let error = (response.result.error as NSError?)
                    
                    if let errorCode = error?.code, Constants.ErrorHandling.RetryNetworkErrors.contains(errorCode) && retryCount > 0 {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(Constants.ErrorHandling.RetryInterval)) {
                            strongSelf.exResponseJSON(retryCount - 1, completionHandler: { (res) in
                                completionHandler(res)
                            })
                        }
                        
                        return
                    }
                    
                    if let errorCode = error?.code, errorCode == NSURLErrorCannotFindHost && dnsRetryCount > 0 {
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(Constants.ErrorHandling.DNSRetryInterval * Double(NSEC_PER_SEC))) {
                            strongSelf.exResponseJSON(retryCount, dnsRetryCount: dnsRetryCount - 1, completionHandler: { (res) in
                                completionHandler(res)
                            })
                        }
                        
                        return
                    }
                    else {
                        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
                            MBProgressHUD.hideAllHUDs(for: window, animated: true)
                        }
                        
                        if let error = error {
                            ErrorLogManager.sharedManager.recordNonFatalError(error)
                        }
                    
                        if let errorCode = error?.code, errorCode == NSURLErrorNotConnectedToInternet {
                            if !CacheManager.sharedManager.promptedSolution {
                                if let viewController = strongSelf.topViewController(), type(of: viewController) !=  MmSolutionViewController.self {
                                    
                                    CacheManager.sharedManager.promptedSolution = true
                                    
                                    Alert.alert(viewController, title: "", message: String.localize("MSG_ERR_NETWORK_1009"), okTitle: String.localize("LB_NETWORK_SOLUTION"), okActionComplete: {
                                            viewController.present(MmSolutionViewController(nibName: "MmSolutionViewController", bundle: nil), animated: true, completion: nil)
                                        }, cancelActionComplete: { 
                                            CacheManager.sharedManager.promptedSolution = false
                                        }
                                    )
                                }
                            }
                            completionHandler(response)
                        } else {
                            strongSelf.showApiErrorPrompt(
                                Utils.formatErrorMessage(
                                    String.localize("MSG_ERR_NETWORK_FAIL"),
                                    error: response.result.error
                                ),
                                completion: {
                                    completionHandler(response)
                                }
                            )
                        }
                    }
                    
                }
            }
            
        )
        return req
    }
    
    fileprivate func showApiErrorPrompt(_ msg: String?, completion: @escaping (() -> Void)) {
        if let vc = self.topViewController(){
            
            //重复的错误提示没有任何意义，体验极差
            var notShow = false
            if let alert = vc as? UIAlertController,let tag = alert.ssn_tag("ALERT_TYPE") as? String,tag == "error alert" {
                notShow = true
            } else if let alert = vc.presentedViewController as? UIAlertController,let tag = alert.ssn_tag("ALERT_TYPE") as? String,tag == "error alert" {
                notShow = true
            }
            if notShow {
                if let msg = msg {
                    print("界面有Error提示，不必反复提示：\"\(msg)\"")
                } else {
                    print("界面有Error提示，不必反复提示：\"\(String.localize("LB_ERROR"))\"")
                }
                return
            }
            
            CATransaction.begin()
            CATransaction.setCompletionBlock({
                
                vc.showErrorAlert(msg ?? String.localize("LB_ERROR"))
                //                UIAlertController.showAlertInViewController(vc, withTitle: "", message: msg, cancelButtonTitle: String.localize("LB_OK"), destructiveButtonTitle: nil, otherButtonTitles: nil, tapBlock: { (controller, action, buttonIndex) -> Void in
                //
                //                })
                completion()
            })
            CATransaction.commit()
        }
    }
    
    @discardableResult
    fileprivate func showUpgradePrompt(forceUpgrade: Bool, appStoreLink: String = Constants.AppStoreLink) -> Bool {
        if let viewController = self.getTopViewController() ?? UIApplication.shared.delegate?.window??.rootViewController {
            return viewController.showUpgradeAlert(forceUpgrade: forceUpgrade, appStoreLink: appStoreLink)
        }
        
        return false
    }
    
    fileprivate func getTopViewController() -> UIViewController? {
        return Utils.findActiveController()
    }
    
    fileprivate func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? { //Fix: Cannot get top view controller to display Alert View
        if let nav = base as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(presented)
        }
        return base
    }
}
