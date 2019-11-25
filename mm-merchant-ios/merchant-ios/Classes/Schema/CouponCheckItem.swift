//
//  CouponCheckItem.swift
//  merchant-ios
//
//  Created by Alan YU on 25/7/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class CouponCheckItem {
    
    fileprivate(set) var merchantId: Int
    fileprivate(set) var brandId: Int
    fileprivate(set) var categoryId: Int?
    fileprivate(set) var qty: Int
    fileprivate(set) var unitPrice: Double
    
    init(merchantId: Int, brandId: Int, categoryId: Int?, unitPrice: Double, qty: Int) {
        self.categoryId = categoryId
        self.merchantId = merchantId
        self.brandId = brandId
        self.unitPrice = unitPrice
        self.qty = qty
    }
    
    func amount() -> Double {
        return unitPrice * Double(qty)
    }
    
}
