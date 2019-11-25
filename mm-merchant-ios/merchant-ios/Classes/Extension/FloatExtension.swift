//
//  FloatExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 21/4/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

extension Float {
    
    static var formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        return formatter
    } ()
    
    static var formatterWithoutComma : NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "zh_Hans_CN")
        formatter.usesGroupingSeparator = false
        formatter.groupingSize = 3
        return formatter
    } ()
    
    func formatQuantity() -> String? {
        Float.formatter.numberStyle = .none
        Float.formatter.minimumFractionDigits = 0
        Float.formatter.maximumFractionDigits = 0
        return Float.formatter.string(from: NSNumber(value: self))
    }

    func formatPrice(currencySymbol: String? = nil) -> String? {
        Float.formatter.numberStyle = .currency
        Float.formatter.minimumFractionDigits = 0
        Float.formatter.maximumFractionDigits = 2
        
        if currencySymbol != nil {
            Float.formatter.currencySymbol = currencySymbol
        } else {
            let locale = Locale(identifier: "zh_Hans_CN")
            if let currencySymbol = (locale as NSLocale).object(forKey: NSLocale.Key.currencySymbol) as? String {
                Float.formatter.currencySymbol = currencySymbol
            }
        }
        
        return Float.formatter.string(from: NSNumber(value: self))?.replacingOccurrences(of: ".00", with: "")
    }
    
    func formatAliPayPrice() -> String {
        Float.formatterWithoutComma.numberStyle = .decimal
        Float.formatterWithoutComma.minimumFractionDigits = 2
        Float.formatterWithoutComma.maximumFractionDigits = 2
        if let payString = Float.formatterWithoutComma.string(from: NSNumber(value: self)) {
            return payString
        }
        return "0.00"
    }

}
