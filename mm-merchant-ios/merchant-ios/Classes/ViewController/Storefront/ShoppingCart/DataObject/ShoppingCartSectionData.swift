//
//  ShoppingCartSectionData.swift
//  merchant-ios
//
//  Created by Alan YU on 10/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class ShoppingCartSectionData: CollectionViewSectionData {
    
    var merchant: CartMerchant?
    var commentText: String?
    var commentBoxColor: UIColor?
    
    var fapiaoText: String?
    var isEnableInputFapiao = false // check if user enable input fapiao text in Confirm Checkout Page
    
    var cartItemCount: Int {
        get {
            var count = 0
            
            for row in self.dataSource {
                if type(of: row) == CartItem.self {
                    count += 1
                }
            }
            
            return count
        }
        set {}
    }
    
    var sectionSelected: Bool {
        get {
            var allSelected = true
            
            for row in self.dataSource {
                if type(of: row) == CartItem.self {
                    if (row as! CartItem).selected == false {
                        allSelected = false
                        break
                    }
                }
            }
            
            return allSelected
        }
        
        set {
            for row in self.dataSource {
                if type(of: row) == CartItem.self {
                    let cartItem = row as? CartItem
                    
                    if cartItem!.isOutOfStock() || !cartItem!.isProductValid() {
                        cartItem?.selected = false
                    } else {
                        cartItem?.selected = newValue
                    }
                }
            }
        }
    }
    
}
