//
//  UIColorExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 14/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

import UIKit

// Color reference: http://www.htmlcsscolor.com/hex/D8D8D8

extension UIColor{
    
    convenience init(hexString: String) {
        self.init(hexStr: hexString, withAlpha: 1.0)
    }
    
    convenience init(hexStr: String, withAlpha alpha: CGFloat) {
        let hexString: String = hexStr.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        
        if (hexString.hasPrefix("#")) {
            scanner.scanLocation = 1
        }
        
        var color:UInt32 = 0
        scanner.scanHexInt32(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        
        self.init(red:red, green:green, blue:blue, alpha:1)
    }
    
    //key theme color
    class func primary1() -> UIColor {
        return UIColor(hexString: "#ed2247") //Amaranth
    }
    class func primary1_disable() -> UIColor {
        return UIColor(hexString: "#F47A90") //Amaranth
    }
    //background
    class func primary2() -> UIColor {
        return UIColor(hexString: "#f1f1f1") //White Smoke
    }
    //Checkout total price
    class func primary3() -> UIColor {
        return UIColor(hexString: "#ef385a") //red
    }
    //border
    class func secondary1() -> UIColor {
        return UIColor(hexString: "#d8d8d8") //Gainsboro
    }                                                                        
    //text
    class func secondary2() -> UIColor {
        return UIColor(hexString: "#4a4a4a") //Charcoal
    }
	
    //transparent text
    class func secondary3() -> UIColor {
        return UIColor(hexString: "#9B9B9B") //Nobel
    }

	//profile title
	class func secondary4() -> UIColor {
		return UIColor(hexString: "#888888") //Grey
	}
    
    class func secondary7() -> UIColor {
        return UIColor(hexString: "#717171")
    }
    
    class func secondary8() -> UIColor {
        return UIColor(hexString: "#848484")
    }
    
    class func secondary9() -> UIColor {
        return UIColor(hexString: "#F7F7F7")
    }
    class func secondary10() -> UIColor {
        return UIColor(hexString: "#E7E7E7")
    }
    class func backgroundGray() -> UIColor {
        return UIColor(hexString: "#ECECEC") //Whisper
    }

    class func sparkingRed() -> UIColor{
        return UIColor(hexString: "FF518B") //French Rose
    }
    
    class func grayTextColor() -> UIColor{
        return UIColor(hexString: "#292929") //Nero
    }
    
    //Checkout Confirmation Page
    class func blackTitleColor() -> UIColor{
        return UIColor(hexString: "292929") //Nero
    }
    
    // Personal information note
    class func noteColor() -> UIColor {
        return UIColor(hexString: "77848E") //Slate Grey
    }
    
    // selected type frame
    class func selectedRed() -> UIColor {
        return UIColor(hexString: "#F95C5C") //Bittersweet
    }
    
    class func secondary5() -> UIColor {
        return UIColor(hexString: "#F3F3F3")
    }
    
    class func secondary11() -> UIColor {
        return UIColor(hexString: "#F0F0F0")
    }
    
    class func secondary12() -> UIColor {
        return UIColor(hexString: "#404040")
    }
    class func secondary13() -> UIColor {
        return UIColor(hexString: "#d1d1d1")
    }
    class func secondary14() -> UIColor {
        return UIColor(hexString: "#9E9E9E")
    }
    
    class func secondary15() -> UIColor {
        return UIColor(hexString: "#333333")
    }
    
    class func secondary16() -> UIColor {
        return UIColor(hexString: "#B2B2B2")
    }
    
    class func secondary17() -> UIColor {
        return UIColor(hexString: "#6B6B6B")
    }
    
    class func whiteColorWithAlpha(_ alpha: CGFloat? = nil) -> UIColor { // white color with alpha
        return UIColor(red: 1, green: 1, blue: 1, alpha: alpha ?? 0.7)
    }
    
    class func imagePlaceholder() -> UIColor {
        return UIColor(hexString: "#F4F4F4")
    }
    
    //profile background 
    class func whiteColorBackground() -> UIColor {
        return UIColor(hexString: "#9B9B9B").withAlphaComponent(0.4)
    }
    
    class func blackColorBackground() -> UIColor {
        return UIColor.black.withAlphaComponent(0.5)
    }
    
    //Review page
    class func ratingStar() -> UIColor {
        return UIColor(hexString: "#f5a623")
    }
    
    class func secondary6() -> UIColor {
        return UIColor(hexString: "#818181")
    }
    
    class func blackLight() -> UIColor {
        return UIColor(hexString: "#262626")
    }
    
    //Alert
    
    class func alertTintColor() -> UIColor {
        return UIColor.secondary2()
    }
    
    // Filter
    
    class func filterBackground() -> UIColor {
        return UIColor(hexString: "#F6F6F6")
    }
    
    // OMS
    
    class func omsBackground() -> UIColor {
        return UIColor(hexString: "#F6F6F6")
    }
    
    // Feed CollectionView Background
    class func feedCollectionViewBackground() -> UIColor{
        return UIColor.white
    }
    
    //Cross label backgroud
    class func crossBorderBackgroundColor() -> UIColor {
        return UIColor(hexString: "#575757")
    }
    
    class func hashtagColor() -> UIColor {
        return UIColor(hexString: "#4a4a4a")
    }
    
    //Shopping cart page
    
    class swipeActionColor {
        enum SwipeActionType: Int {
            case add = 0,
            edit,
            delete
        }
        
        class func backgroundColor(swipeActionType type: SwipeActionType) -> UIColor{
            switch type {
            case .add:
                return UIColor(hexString: "#c0c0c0")
            case .edit:
                return UIColor(hexString: "#E86763")
            case .delete:
                return UIColor(hexString: "#7A848C")
            }
        }
    }
    
    //My Account birthday pickerview
    
    class func redDoneButton() -> UIColor {
        
        return UIColor(hexString: "#EE3053")
    }
    
    //Login wechat button
    
    class func wechatButtonColor() -> UIColor {
        
        return UIColor(hexString: "#42ae3a")
    }
    
    class func weiboButtonColor() -> UIColor {
        return UIColor(hexString: "#3F51B5")
    }
    
    private struct ColorComponents {
        var red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat
    }
    
    private func getComponents() -> ColorComponents {
        if (self.cgColor.numberOfComponents == 2) {
            let cc = self.cgColor.components
            return ColorComponents(red: cc![0], green: cc![0], blue: cc![0], alpha: cc![1])
        }
        else {
            let cc = self.cgColor.components
            return ColorComponents(red: cc![0], green: cc![1], blue: cc![2], alpha: cc![3])
        }
    }
    
    class func colorBetween(_ startColor: UIColor, destinationColor: UIColor, fraction: CGFloat) -> UIColor {
        
        var f = max(0, fraction)
        f = min(1, fraction)
        
        let startComponent = startColor.getComponents()
        let destinationComponent = destinationColor.getComponents()
        
        let red = startComponent.red + (destinationComponent.red - startComponent.red) * f
        let green = startComponent.green + (destinationComponent.green - startComponent.green) * f
        let blue = startComponent.blue + (destinationComponent.blue - startComponent.blue) * f
        let alpha = startComponent.alpha + (destinationComponent.alpha - startComponent.alpha) * f
        
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
}

