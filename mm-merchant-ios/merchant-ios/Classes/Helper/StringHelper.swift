//
//  StringHelper.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class StringHelper {
    class func getTextWidth(_ text: String, height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.width
    }
    
    @available(*, deprecated, message : "should use heightForText(_:width:font)")
    class func getTextHeight(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
        return boundingBox.height
    }
    
    class func heightForText(_ text: String, width: CGFloat, font: UIFont) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
    
    class func formatPhoneNumber(_ phoneNumber: String) -> String {
        var characters = Array(phoneNumber)
        let  max = 4
        
        for (index, _) in characters.enumerated() {
            if index > (max - 1 ) && index <= (max - 1 ) + max {
                characters[index] = "*"
            }
        }
        var result = ""
        for (_, element) in characters.enumerated() {
            result += String(element)
        }
        return result
    }
    
    
}
