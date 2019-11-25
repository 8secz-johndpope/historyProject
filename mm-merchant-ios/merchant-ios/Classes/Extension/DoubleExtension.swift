//
//  DoubleExtension.swift
//  merchant-ios
//
//  Created by Tony Fung on 19/8/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation

extension Double {
    
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
        Double.formatter.numberStyle = .none
        Double.formatter.minimumFractionDigits = 0
        Double.formatter.maximumFractionDigits = 0
        return Double.formatter.string(from: NSNumber(value: self))
    }
    
    func formatPrice(currencySymbol: String? = nil) -> String? {
        Double.formatter.numberStyle = .currency
        Double.formatter.minimumFractionDigits = 0
        Double.formatter.maximumFractionDigits = 2
        
        if currencySymbol != nil {
            Double.formatter.currencySymbol = currencySymbol
        }
        
        return Double.formatter.string(from: NSNumber(value: self))?.replacingOccurrences(of: ".00", with: "")
    }
    
    func formatPriceWithoutCurrencySymbol() -> String? {
        Double.formatter.numberStyle = .decimal
        Double.formatter.minimumFractionDigits = 0
        Double.formatter.maximumFractionDigits = 2
        
        return Double.formatter.string(from: NSNumber(value: self))?.replacingOccurrences(of: ".00", with: "")
    }

    func formatAliPayPrice() -> String {
        Double.formatterWithoutComma.numberStyle = .decimal
        Double.formatterWithoutComma.minimumFractionDigits = 2
        Double.formatterWithoutComma.maximumFractionDigits = 2
        if let payString = Double.formatterWithoutComma.string(from: NSNumber(value: self)) {
            return payString
        }
        return "0.00"
    }
    
}
