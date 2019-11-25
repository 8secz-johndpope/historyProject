//
//  AppUpgradeHelper.swift
//  merchant-ios
//
//  Created by Kam on 13/12/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import Alamofire
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class AppUpgradeHelper {
    
    class func checkAppUpgrade(_ response: DataResponse<Any>) {
        if let headers = response.response?.allHeaderFields {
            if let forceUpgrade = headers["ForceUpgrade"] as? String, forceUpgrade == "true" {
                if let serverAppStoreLink = headers["AppURL"] as? String {
                    self.promptUpgrade(forceUpgrade: true, appStoreLink: serverAppStoreLink)
                } else {
                    self.promptUpgrade(forceUpgrade: true)
                }
            } else if let appLatestVersion = headers["AppLatestVersion"] as? String {
                var textAppVersions = Constants.AppVersion.split(separator: ".")
                var textAppLatestVersions = appLatestVersion.split(separator: ".")
                
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
                    let lastPromptTime = Context.getLastAppUpgradeAlertPromptTime()
                    
                    if lastPromptTime == nil || lastPromptTime?.timeIntervalSinceNow < -86400 {
                        
                        var alertIsShown = false
                        var forceUpgrade = false
                        
                        if let force = headers["ForceUpgrade"] as? String, force == "true" {
                            forceUpgrade = true
                        }
                        
                        if let serverAppStoreLink = headers["AppURL"] as? String {
                            alertIsShown = self.promptUpgrade(forceUpgrade: forceUpgrade, appStoreLink: serverAppStoreLink)
                        } else {
                            alertIsShown = self.promptUpgrade(forceUpgrade: forceUpgrade)
                        }
                        
                        if alertIsShown {
                            Context.setLastAppUpgradeAlertPromptTime(Date())
                        }
                    }
                }
            }
        }
    }

    @discardableResult
    private class func promptUpgrade(forceUpgrade: Bool, appStoreLink: String? = Constants.AppStoreLink) -> Bool {
        if let viewController = self.getTopViewController() {
            if let appStoreLink = appStoreLink {
                return viewController.showUpgradeAlert(forceUpgrade: forceUpgrade, appStoreLink: appStoreLink)
            } else {
                return viewController.showUpgradeAlert(forceUpgrade: forceUpgrade)
            }
        }
        return false
    }
    
    private class func getTopViewController() -> UIViewController? {
        if let adelegate : AppDelegate = UIApplication.shared.delegate as? AppDelegate {
            if let nvc: UINavigationController = adelegate.window?.rootViewController as? UINavigationController {
                return nvc.viewControllers[0]
            } else {
                return adelegate.window?.rootViewController as UIViewController?
            }
        }
        return nil
    }
    
    private func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? { //Fix: Cannot get top view controller to display Alert View
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
