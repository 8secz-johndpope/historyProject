//
//  SlideMenuCollectionViewCell.swift
//  storefront-ios
//
//  Created by Kam on 23/3/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

protocol SlideMenu_Enum  {
    var deeplink: String { get }
    var isModal: Bool { get }
    var title: String { get }
    var icon: String { get }
}

enum MENU_ITEM_TYPE : Int, SlideMenu_Enum {
    case post = 0,
    notification,
//    chat,
    order,
    coupon,
//    cart,
    favourite,
    vip,
    setting,
    count
    
    var deeplink: String {
        switch self {
        case .post:
            return Navigator.mymm.deeplink_dk_posting
        case .notification:
            return Navigator.mymm.socialNotification
//        case .chat:
//            return Navigator.mymm.imLanding
        case .favourite:
            return Navigator.mymm.user_collection
        case .coupon:
            return Navigator.mymm.coupon_container
//        case .cart:
//            return Navigator.mymm.website_cart
        case .order:
            return Navigator.mymm.website_order_list
        case .vip:
            return Navigator.mymm.deeplink_vu_userKey + Context.getUserKey()
        case .setting:
            return Navigator.mymm.setting
        default: return ""
        }
    }
    
    var isModal: Bool {
        switch self {
        case .post:
            return true
        default:
            return false
        }
    }
    
    var title: String {
        switch self {
        case .post:
            return String.localize("LB_CA_POST")
        case .notification:
            return String.localize("LB_CA_NOTIFICATIONS")
//        case .chat:
//            return String.localize("LB_CA_CHAT_TITLE")
        case .favourite:
            return String.localize("LB_CA_MY_COLLECTION")
        case .coupon:
            return String.localize("LB_CA_MENU_COUPON_ENTRANCE")
//        case .cart:
//            return String.localize("LB_CA_CART")
        case .order:
            return String.localize("LB_CA_MY_ORDERS")
        case .vip:
            return String.localize("LB_CA_VIC_CENTER")
        case .setting:
            return String.localize("LB_CA_SETTINGS")
        default: return ""
        }
    }
    
    var icon: String {
        switch self {
        case .post:
            return "slidemenu_camera"
        case .notification:
            return "slidemenu_notification"
//        case .chat:
//            return "slidemenu_im"
        case .favourite:
            return "slidemenu_star"
        case .coupon:
            return "slidemenu_coupon"
//        case .cart:
//            return "slidemenu_bag"
        case .order:
            return "slidemenu_order"
        case .vip:
            return "slidemenu_vip"
        case .setting:
            return "slidemenu_setting"
        default: return ""
        }
    }
}

class SlideMenuCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func setData(index: Int) {
        if let item = MENU_ITEM_TYPE(rawValue: index) {
            self.iconImage.image = UIImage(named: item.icon)
            self.titleLabel.text = item.title
            badgeLabel.isHidden = true
            var unreadCount = 0
            switch item {
            case .notification:
                unreadCount = SocialMessageManager.sharedManager.socialMessageUnreadCount
//            case .chat:
//                unreadCount = WebSocketManager.sharedInstance().numberOfUnread
            case .coupon:
                unreadCount = CacheManager.sharedManager.hasNewClaimedCoupon ? 1 : 0
//            case .cart:
//                unreadCount = CacheManager.sharedManager.numberOfCartItems()
            default:
                break
            }
            badgeLabel.isHidden = !(unreadCount > 0)
            
            if item == .coupon {
                badgeLabel.text = ""
                let reddotSize: CGFloat = 6.0
                badgeLabel.frame = CGRect(x: 210, y: 18, width: reddotSize, height: reddotSize)
            } else {
                badgeLabel.text = unreadCount > 99 ? "99+" : "\(unreadCount)"
                let reddotSize: CGFloat = 18.0
                badgeLabel.frame = CGRect(x: 204, y: 12, width: max(badgeLabel.optimumWidth() + 4, reddotSize), height: reddotSize)
            }
            badgeLabel.round()
        }
    }
}
