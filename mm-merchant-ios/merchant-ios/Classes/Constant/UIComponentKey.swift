//
//  UIComponentKey.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 23/5/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

struct UIComponentKey {
    struct TabBar {
        struct Item {
            static let Magazine =   "TabBar_Item_Magazine"
            static let Browse =  "TabBar_Item_Browse"
            static let HomePage =   "TabBar_Item_Homepage"
            static let Chat =       "TabBar_Item_Chat"
            static let Profile =    "TabBar_Item_Profile"
        }
    }
    struct NavigationBar {
        struct Item {
            static let CartButton = "view_cart_button"
            static let WishListButton = "view_wishlist_button"
        }
    }
}
