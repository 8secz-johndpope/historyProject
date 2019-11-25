//
//  UIBarButtonItemExt.swift
//  storefront-ios
//
//  Created by MJ Ling on 2018/9/5.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

/**
 * MM所有头部按钮样式实现
 */
extension UIBarButtonItem {
    
    // 顶部消息按钮
    static func messageButtonItem(_ target: Any?, action: Selector) -> UIBarButtonItem {
        let btn = MessageButtonItem(number: 0)
        btn.frame = CGRect(x: 0, y: 0, width: 21, height: 18)
        btn.setImage(UIImage(named: "message"), for: .normal)
        btn.addTarget(target, action: action, for: UIControlEvents.touchUpInside)
        
        let rightBarButton = UIBarButtonItem(customView: btn)
        rightBarButton.track_consoleTitle = "消息"
        return rightBarButton
    }
    
    static func menuButtonItem(_ target: Any?, action: Selector)  -> UIBarButtonItem {
        let btn = MessageButtonItem(type: .custom)
        btn.redDotAdjust = CGPoint(x: -3, y: 0)
        btn.frame = CGRect(x: 0, y: 0, width: 18, height: 15)
        btn.setImage(UIImage(named: "menu_ic"), for: .normal)
        btn.addTarget(target, action: action, for: UIControlEvents.touchUpInside)
        let leftBarButton = UIBarButtonItem(customView: btn)
        leftBarButton.track_consoleTitle = "主菜单"
        return leftBarButton
    }
}


// MARK: 一些按钮相关逻辑具体实现
//消息按钮逻辑实现
fileprivate class MessageButtonItem: ButtonRedDot {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        leftObserved()
        leftBadgeUpdate()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(number: Int) {
        super.init(number: number)
        rightObserved()
        rightBadgeUpdate()
    }
    
    private func leftObserved() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.leftBadgeUpdate), name: NSNotification.Name(rawValue: SocialMessageUnreadChangedNotification), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.leftBadgeUpdate), name: Constants.Notification.couponClaimedDidUpdate, object: nil)
    }
    
    private func rightObserved() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.rightBadgeUpdate), name: NSNotification.Name(rawValue: IMDidUpdateUnreadBadgeNumber), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.rightBadgeUpdate), name: Constants.Notification.loginSucceed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.imWebSocketConnected), name: NSNotification.Name(rawValue: IMDidWebsocketConnected), object: nil) // 是在子线程中发送的post
    }

    @objc private func leftBadgeUpdate() {
        self.hasRedDot(false)
        if LoginManager.isValidUser() {
            if SocialMessageManager.sharedManager.socialMessageUnreadCount > 0 || CacheManager.sharedManager.hasNewClaimedCoupon {
                self.hasRedDot(true)
            }
        }
    }
    
    @objc private func imWebSocketConnected() {
        DispatchQueue.main.async {
            self.rightBadgeUpdate()
        }
    }
    
    @objc private func rightBadgeUpdate() {
        self.setBadgeNumber(WebSocketManager.sharedInstance().numberOfUnread)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
