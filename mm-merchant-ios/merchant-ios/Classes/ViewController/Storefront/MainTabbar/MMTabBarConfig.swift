//
//  MMTabBarConfig.swift
//  storefront-ios
//
//  Created by Demon on 24/8/18.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import Foundation

enum MMTabBarType: Int {

    case homePage = 0,
    categoryPage,
    brandPage,
    shoppingCart,
    minePage
    
    func getViewController() -> (nav: MmNavigationController?, tabbarInfo: MMTabbarInfo?) {
        switch self {
        case .homePage:
            return getNav(url: Navigator.mymm.mymm_website_home_alias)
        case .categoryPage:
            return getNav(url: Navigator.mymm.website_category)
        case .brandPage:
            return getNav(url: Navigator.mymm.website_brandlist)
        case .shoppingCart:
           return getNav(url: Navigator.mymm.website_cart)
        case .minePage:
            return getNav(url: Navigator.mymm.website_account)
        }
    }
    
    private func getNav(url: String) -> (MmNavigationController?, tabbarInfo: MMTabbarInfo?) {
        if let vc = Navigator.shared.getViewController(url) {
            let info = MMTabbarInfo()
            info.tabbarName = vc._node.des
            info.auth = vc._node.auth
            vc.tabBarItem.title = ""
            vc.tabBarItem.isEnabled = false
            let nav = MmNavigationController(rootViewController: vc)
            nav.tabBarItem.isEnabled = false
            nav.tabBarItem.title = ""
            return (nav, info)
        }
        return (nil, nil)
    }
    
    func getTabbarImageName() -> (tababrName: String, tabbarSelectName: String) {
        switch self {
        case .homePage:
            return ("hp_icon", "hp_icon_selected")
        case .categoryPage:
            return ("cat_icon", "cat_icon_selected")
        case .brandPage:
            return ("brand_icon", "brand_icon_selected")
        case .shoppingCart:
            return ("cart_icon", "cart_icon_selected")
        case .minePage:
            return ("me_icon_d", "me_icon_selected")
        }
    }
}

extension MMTabBarController {
    
    public func defaultTabbarInfo(_ completion:((_ tabbarInfos: [MMTabbarInfo]) -> Void)?) {
        let vcs = [MMTabBarType.homePage, MMTabBarType.categoryPage, MMTabBarType.brandPage, MMTabBarType.shoppingCart, MMTabBarType.minePage]
        var tbInfos = [MMTabbarInfo]()
        for (index, pageType) in vcs.enumerated() {
            let tuple = pageType.getViewController()
            let imageTuple = pageType.getTabbarImageName()
            if let nav = tuple.nav, let info = tuple.tabbarInfo {
                info.tabbarItemIndex = index
                info.tabbarImageName = imageTuple.tababrName
                info.tabbarSelectedImageName = imageTuple.tabbarSelectName
                tbInfos.append(info)
                self.addChildViewController(nav)
            }
        }
        if let tabbarBlock = completion {
            tabbarBlock(tbInfos)
        }
    }
    
}

class MMTabbarInfo {
    
    var tabbarName: String = ""
    var tabbarImageName: String = ""
    var tabbarSelectedImageName = ""
    var tabbarItemIndex = 0
    var tabbarImageURL = ""
    var tabbarLinkURL = ""
    var auth = false
    
}

