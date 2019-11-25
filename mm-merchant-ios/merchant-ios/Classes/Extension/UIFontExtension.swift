//
//  UIFontExtension.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 3/22/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

extension UIFont {
    class func fontLightWithSize(_ size: CGFloat) -> UIFont {
        if #available(iOS 9, *) {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.light)
        }
        else {
            return UIFont.systemFont(ofSize: size)
        }
    }
    
    class func fontRegularWithSize(_ size: CGFloat) -> UIFont {
        if #available(iOS 9, *) {
            return UIFont.systemFont(ofSize: size, weight: UIFont.Weight.regular)
        }
        else {
            return UIFont.systemFont(ofSize: size)
        }
    }
    
    class func usernameFont() -> UIFont {
        if let font = UIFont(name: Constants.Font.Bold, size: 15) {
            return font
        }
        
        return UIFont.boldSystemFont(ofSize: 15)
    }
    
    class func systemFontWithSize(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: Constants.Font.Normal, size: size) {
            return font
        }
        
        return UIFont.systemFont(ofSize: size)
    }
    
    class func boldFontWithSize(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: Constants.Font.Bold, size: size) {
            return font
        }
        
        return UIFont.systemFont(ofSize: size)
    }
    
    class func thinFontWithSize(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: Constants.Font.Thin, size: size) {
            return font
        }
        
        return UIFont.systemFont(ofSize: size)
    }

    class func ultralightFontWithSize(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: Constants.Font.Ultralight, size: size) {
            return font
        }
        
        return UIFont.systemFont(ofSize: size)
    }
    
    class func fontWithSize(_ size: Int, isBold: Bool) -> UIFont {
        if let font = UIFont(name: isBold ? Constants.Font.Bold : Constants.Font.Normal, size: CGFloat(size)) {
            return font
        } else {
            return UIFont.systemFont(ofSize: CGFloat(size))
        }
    }
    
    static func regularFontWithSize(size: CGFloat)  -> UIFont {
        if let font = UIFont(name: Constants.Font.Regular, size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }

}
