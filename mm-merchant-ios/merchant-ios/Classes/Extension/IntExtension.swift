//
//  IntExtension.swift
//  merchant-ios
//
//  Created by Alan YU on 9/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

extension Int {
    
    static var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        return formatter
    } ()
    
    func formatQuantity() -> String? {
        Int.formatter.numberStyle = .none
        Int.formatter.minimumFractionDigits = 0
        Int.formatter.maximumFractionDigits = 0
        return Int.formatter.string(from: NSNumber(value: self))
    }
    
    func formatPrice(currencySymbol: String? = nil) -> String? {
        Int.formatter.numberStyle = .currency
        Int.formatter.minimumFractionDigits = 0
        Int.formatter.maximumFractionDigits = 0
        
        if currencySymbol != nil {
            Int.formatter.currencySymbol = currencySymbol
        }
        
        return Int.formatter.string(from: NSNumber(value: self))
    }
    
    func toString() -> String{
        return "\(self)"
    }
    
    func times(f: () -> ()) {
        if self > 0 {
            for _ in 0..<self {
                f()
            }
        }
    }
    
    func times( f: @autoclosure () -> ()) {
        if self > 0 {
            for _ in 0..<self {
                f()
            }
        }
    }
}
