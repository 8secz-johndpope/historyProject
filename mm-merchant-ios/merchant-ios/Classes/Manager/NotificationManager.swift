//
//  NotificationManager.swift
//  merchant-ios
//
//  Created by Tony Fung on 11/4/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

enum PushNotificationType: String {
    case FriendRequest  = "fr"
    case NewbieCoupon   = "nc"
    case Referrer       = "rr"
    case Referee        = "re"
    case RefereeNewbie  = "rn"
    case RefereeM       = "rm"
    case SocialNotificationLike = "dk/pl"
    case SocialNotificationComment = "dk/pc"
    case SocialNotificationFollowers = "dk/fl"
}

class NotificationManager {
    
    class var sharedManager: NotificationManager {
        get {
            struct Singleton {
                static let instance = NotificationManager()
            }
            return Singleton.instance
        }
    }
    
    func handleReceiveNotification(_ active: Bool, userInfo: [AnyHashable: Any]){
        
        switch active {
        case true:
            
            if let dataType = userInfo["DataType"] as? String, let dataBody = userInfo["Data"] as? String, let aps = userInfo["aps"] as? [AnyHashable: Any] {
                switch dataType {
                case PushNotificationType.FriendRequest.rawValue:
                    NSLog("%@", "Here is Friend Request")
                    let value = CacheManager.sharedManager.numberOfFriendRequests + 1
                    CacheManager.sharedManager.updateNumberOfFriendRequests(value, notify: true)
                case PushNotificationType.Referee.rawValue,
                     PushNotificationType.Referrer.rawValue,
                     PushNotificationType.RefereeNewbie.rawValue:
//                     PushNotificationType.RefereeM.rawValue,
//                     PushNotificationType.NewbieCoupon.rawValue:
                    if let messageId = userInfo["_j_msgid"] as? Int {
                        showNewbieCouponNotification(messageId, dataType: dataType, dataBody: dataBody, aps: aps)
                    }
                    CouponManager.shareManager().invalidate(wallet: Constants.MMMerchantId)
                case PushNotificationType.SocialNotificationLike.rawValue,
                     PushNotificationType.SocialNotificationComment.rawValue,
                     PushNotificationType.SocialNotificationFollowers.rawValue:
                    
                    SocialMessageManager.sharedManager.getSocialMessageUnreadCount()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: SocialMessageDidUpdateNotification), object: nil)
                    
                default:
                    break
                }
            }
            break
            
        case false:
            
            if let dataType = userInfo["DataType"] as? String, let dataBody = userInfo["Data"] as? String{
                
                let value = dataBody.replacingOccurrences(of: "&amp;", with: "&")
                //                url = String.format("https://%s/%s/%s", Constant.SHARING_HOST, type, value)
                let urlString = "https://m.mymm.com/\(dataType)/\(value)"
                switch dataType {
                case PushNotificationType.FriendRequest.rawValue:
                    let value = CacheManager.sharedManager.numberOfFriendRequests + 1
                    CacheManager.sharedManager.updateNumberOfFriendRequests(value, notify: true)
                default:
                    break
                }
                triggerAction(dataType, dataBody: dataBody, originUrl: urlString)
            }
            break
        }
        
    }
    
    func triggerAction(_ dataType: String, dataBody: String, originUrl: String){
        if !LoginManager.hasStorefront() && LoginManager.getLoginState() != .validUser {
            return
        }

        let block :(() -> Void) = {
            Navigator.shared.dopen(originUrl)
        }
        
        let storefrontVC = LoginManager.getStorefront()
        if storefrontVC?.presentedViewController != nil {
            storefrontVC?.dismiss(animated: false, completion: block)
        } else {
            block()
        }
    }
    
    func showNewbieCouponNotification(_ msgId: Int, dataType: String, dataBody: String, aps: [AnyHashable: Any]) {
        DropDownBanner.backgroundColor = UIColor.black
        DropDownBanner.titleColor = UIColor.white
        DropDownBanner.subtitleColor = UIColor.white

        let image = Merchant().MMImageIconBlack
        let title = String.localize("LB_CA_COUPON_NEWBIE_NOTE_TITLE")

        // duration > 0 - auto dismiss
        // duration = 0 - no auto dismiss
        if let message = aps["alert"] as? String {
            let announcement = Announcement(title: title, subtitle: message, image: image, duration: 0, action: { [weak self] in
                
                    if let strongSelf = self {
                        // action tap analytic
                        if let currentVC = Utils.findActiveController() as? MmViewController {
                            currentVC.view.recordAction(.Tap, sourceRef: String(msgId), sourceType: .InAppNotification, targetRef: "MyCoupon", targetType: .View)
                        }
                        
//                        strongSelf.triggerAction(dataType, dataBody: dataBody)
                        strongSelf.pushToMyCoupon()
                    }

                }, swipeToDismiss: { 
                    // action swipe to dissmiss analytic
                    if let currentVC = Utils.findActiveController() as? MmViewController {
                        currentVC.view.recordAction(.Swipe, sourceRef: String(msgId), sourceType: .InAppNotification, targetType: .Hide)
                    }
            })
            
            shoutView.show(announcement, completion: nil)

            // impression analytic
            if let currentVC = Utils.findActiveController() as? MmViewController {

                let impressionKey = currentVC.recordImpression(impressionRef: String(msgId), impressionType: "InAppNotification", impressionDisplayName: message, positionComponent: "InAppNotification", positionLocation: "\(type(of: currentVC))")
                currentVC.view.initAnalytics(withViewKey: currentVC.analyticsViewRecord.viewKey, impressionKey: impressionKey)
            }

        }
        
    }
    
    func pushToMyCoupon() {
        if let storefront = LoginManager.getStorefront(), let nav = storefront.selectedViewController as? UINavigationController, let strongController = nav.topViewController {
            let delayTime = DispatchTime.now() + Double(Int64(0.3 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) {
                let block:() -> () = {
                    let myCouponVC = MyCouponViewController()
                    strongController.navigationController?.pushViewController(myCouponVC, animated: false)
                }
                
                if let present = strongController.presentedViewController {
                    present.dismiss(animated: false, completion: block)
                } else{
                    block()
                }
            }
        }
    }
    
    func pushToChat() {
        if let storefront = LoginManager.getStorefront(), let nav = storefront.selectedViewController as? UINavigationController, let strongController = nav.topViewController {
            OperationQueue.main.addOperation({
                let block: () -> () = {
                    let vc = UserChatViewController(convKey: "")
                    strongController.navigationController?.pushViewController(vc, animated: true)
                }
                if let present = strongController.presentedViewController {
                    present.dismiss(animated: false, completion: block)
                } else{
                    block()
                }
            })
        }
    }
}
