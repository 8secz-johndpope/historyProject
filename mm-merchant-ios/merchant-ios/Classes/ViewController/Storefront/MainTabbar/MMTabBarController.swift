//
//  MMTabBarController.swift
//  storefront-ios
//
//  Created by Demon on 24/8/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit

class MMTabBarController: UITabBarController, MMTabBarDelegate {
    
    private var tabbarInfos: [MMTabbarInfo]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setValue(mmTabBar, forKey: "tabBar")
        defaultTabbarInfo { (tabbarInfos) in
            self.mmTabBar.buildTabBarItem(infos: tabbarInfos)
            self.tabbarInfos = tabbarInfos
        }
        
        self.registerNotification()
    }

    public func showMenuController() {
        let menuVC = SlideMenuViewController()
        present(menuVC, animated: false, completion: nil)
    }

    /// 切换tabbarItem
    public func setSelectIndex(index: Int) {
        tabbarItemSelected(index: index)
    }
    
    // MARK: -  MMTabBarDelegate
    
    func tabbarItemSelected(index: Int) {
        if index == selectedIndex {
            return
        }
        if let tabbarInfos = self.tabbarInfos, tabbarInfos.count > index {
            let tabbarInfo = tabbarInfos[index]
            if tabbarInfo.auth && LoginManager.getLoginState() != .validUser {
                LoginManager.goToLogin()
                return
            }
            selectedIndex = index
            self.mmTabBar.changeItemStatus(selectedIndex: selectedIndex)
        }
    }
    
    /// 更新购物车数量
    @objc private func updateShoppingCartNumber() {
        if LoginManager.isValidUser() {
            let cartNumber = CacheManager.sharedManager.numberOfCartItems()
            let tabbarItem = self.mmTabBar.buttonItems[MMTabBarType.shoppingCart.rawValue]
            if cartNumber > 0 {
                tabbarItem.badgeText = "\(cartNumber)"
            } else {
                tabbarItem.badgeText = nil
            }
        }
    }
    
    private func registerNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateShoppingCartNumber), name: Constants.Notification.updateCartBadgeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateShoppingCartNumber), name: Constants.Notification.loginSucceed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateShoppingCartNumber), name: Notification.Name(rawValue: "refreshShoppingCartFinished"), object: nil)
        self.updateShoppingCartNumber()
    }
    
    // MARK: -  lazyload
    lazy var mmTabBar: MMTabBar = {
       let c = MMTabBar()
        c.itemDelegate = self
        return c
    }()

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

}
