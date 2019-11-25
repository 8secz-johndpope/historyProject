//
//  NumberHelper.swift
//  merchant-ios
//
//  Created by Trung Vu on 3/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class NumberHelper {
    
    
    static func getNumberMeasurementString(_ number: Int) -> String {
        let currentLanguage = Context.getCc()
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        
        switch (currentLanguage) {
        case "EN":
            if(number > 999999) {
                return String.init(format: "%dm", number / 1000000)
            } else if(number > 9999) {

                return String.init(format: "%dk", number / 10000)
            } else if(number > 999) {
                if let formattedNumber = numberFormatter.string(from: number as NSNumber) {
                    return formattedNumber
                }
            }
            
        case "CHT":
            if(number > 99999) {
                return String.init(format: "%d萬", number / 10000)
            } else if(number > 999) {
                if let formattedNumber = numberFormatter.string(from: number as NSNumber) {
                    return formattedNumber
                }
            }
            
        case "CHS":
            if(number > 99999) {
                return String.init(format: "%d万", number / 10000)
            } else if(number > 999) {
                if let formattedNumber = numberFormatter.string(from: number as NSNumber) {
                    return formattedNumber
                }
            }

        default:
            break
        }
        return String(number)
    }
    class func formatLikeAndCommentCount(_ count: Int) -> String {
        
        let cnt = count < 0 ? 0 : count
        
        var result = String(cnt)
        if (cnt > 9999) {
            let offset = (cnt % 10000)/1000
            if offset == 0 {
                result =  String.init(format: "%d", cnt / 10000) + "万"
            }else {
                result =  String.init(format: "%d.%d", cnt / 10000, offset) + "万"
            }
            
        }
        return result;
    }
}
