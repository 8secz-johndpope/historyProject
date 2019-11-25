//
//  Utils.swift
//  merchant-ios
//
//  Created by Alan YU on 18/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

import AVFoundation
import Photos
import Kingfisher
import PromiseKit
import CFNetwork

class Utils {
    static func UUID () -> String {
        return Foundation.UUID().uuidString
    }
	
    
    static func checkCameraPermissionWithCallBack(_ completion: ((Bool) -> Void)?) {
        
        var grantedAccess = false
        
        let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        switch authStatus {
        case .authorized:
            grantedAccess = true
            break
        case .denied:
            break
        case .notDetermined:
            break
        default:
            break
        }
        
        if !grantedAccess {
            
            if authStatus == .notDetermined {
                // checkCameraPermission
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {granted in
                    DispatchQueue.main.async {
                        if !granted {
                            TSAlertView_show(String.localize("LB_CA_IM_ACCESS_CAMERA_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_CAMERA_DENIED"), labelCancel: nil)
                        }
                        if let block = completion {
                            block(granted)
                        }
                    }
                })
            }else {
                TSAlertView_show(String.localize("LB_CA_IM_ACCESS_CAMERA_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_CAMERA_DENIED"), labelCancel: nil)
            }
            
        }
        
        if let block = completion {
            DispatchQueue.main.async {
                block(grantedAccess)
            }
        }
    }

    
    static func checkPhotoPermission() -> PHAuthorizationStatus {
        var grantedAccess = false
        
        let authStatus = PHPhotoLibrary.authorizationStatus()
        switch authStatus {
        case .authorized:
            grantedAccess = true
            break
        case .denied:
            break
        case .notDetermined:
            grantedAccess = true
        default:
            break
        }
        
        if !grantedAccess {
            TSAlertView_show(String.localize("LB_CA_IM_ACCESS_PHOTOS_PERMIT"), message: String.localize("LB_CA_IM_ACCESS_PHOTOS_DENIED"), labelCancel: nil)
        }
        
        return authStatus
    }
    
    static func fetchImages(_ urls: [URL], completion: (([UIImage]) -> Void)?) {
        var promise = [Promise<(URL?, UIImage?)>]()
        for url in urls {
            promise.append(
                Promise<(URL?, UIImage?)> { fufill, fail in
                    if url.scheme == "MM" && url.host == "icon" {
                        fufill((url, UIImage(named: "mm_black")))
                    } else {
                        KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) in
                            fufill((imageURL, image ?? UIImage(named: "default_profile_pic")!))
                        })
                    }
                }
            )
        }
        
        when(fulfilled: promise)
            .then { data -> Void in
                var orderedList = [UIImage]()
                for url in urls {
                    for (imageURL, image) in data {
                        if let img = image, url == imageURL {
                            orderedList.append(img)
                        }
                    }
                }
                completion?(orderedList)
        }
    }
    
    class func findActiveController() -> UIViewController? {
        if let window = UIApplication.shared.delegate!.window {
            if let rootViewController = window!.rootViewController as? MMTabBarController {
                if let navigationController = rootViewController.selectedViewController as? UINavigationController {
                    if let activeController = navigationController.topViewController, ((activeController as? MmViewController) != nil) || ((activeController as? MMUIController) != nil) {
                        return activeController
                    }
                }
            }
        }
        
        return nil
    }
    
    class func findActiveNavigationController() -> UINavigationController? {
        if let window = UIApplication.shared.delegate!.window {
            if let rootViewController = window!.rootViewController as? MMTabBarController {
                if let navigationController = rootViewController.selectedViewController as? UINavigationController {
                    return navigationController
                }
            }
        }
        
        return nil
    }
    
    
    class func formatErrorMessage(_ message: String, error: Error?) -> String {
        var result = message
        if let e = error as NSError? {
            if e.code == NSURLErrorNotConnectedToInternet {
                result = String.localize("MSG_ERR_NETWORK_1009")
            } else if e.code == NSURLErrorTimedOut {
                result = String.localize("MSG_ERR_NETWORK_1001")
            }
        }
        return result
    }
    
    static func requestLocationAndPushNotification() {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            registerPushToken(appDelegate)
            LocationManager.sharedInstance().start()
        }
    }
    
    static private func registerPushToken(_ delegate: AppDelegate){
        if Device.TheCurrentDeviceVersion >= 10.0 {
            let entity = JPUSHRegisterEntity()
            entity.types = Int(JPAuthorizationOptions.alert.rawValue | JPAuthorizationOptions.badge.rawValue | JPAuthorizationOptions.sound.rawValue)
            JPUSHService.register(forRemoteNotificationConfig: entity, delegate: delegate)
        } else if Device.TheCurrentDeviceVersion >= 8.0 {
            JPUSHService.register(forRemoteNotificationTypes: UIUserNotificationType.badge.rawValue | UIUserNotificationType.badge.rawValue | UIUserNotificationType.alert.rawValue , categories: nil)
        }
        logNotificationEnabled()
    }
    
    static func logNotificationEnabled() {
        let PreferenceKey = "isRegisteredForRemoteNotifications"
        let preferences = UserDefaults.standard
        let isRegistered = UIApplication.shared.isRegisteredForRemoteNotifications
        
        // record for empty
        var shouldRecord = true
        if let obj = preferences.object(forKey: PreferenceKey) as? Bool {
            // record if difference
            shouldRecord = obj != isRegistered
        }
        
        if shouldRecord {
            var targetRef = "No"
            if isRegistered {
                targetRef = "Yes"
            }
            
            let actionRecord = AnalyticsManager.createActionRecord(
                analyticsViewKey: "",
                actionTrigger: .Tap,
                sourceRef: "Permission-Push",
                sourceType: .Button,
                targetRef: targetRef,
                targetType: .Permission
            )
            AnalyticsManager.sharedManager.recordAction(actionRecord)
            
            preferences.set(isRegistered, forKey: PreferenceKey)
            preferences.synchronize()
        }
    }
}
