//
//  UIColorEx.swift
//  LiquidLoading
//
//  Created by Takuma Yoshida on 2015/08/21.
//  Copyright (c) 2015年 yoavlt. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    var redValue: CGFloat {
        get {
            let components = self.cgColor.components
            return components![0]
        }
    }
    
    var greenValue: CGFloat {
        get {
            let components = self.cgColor.components
            return components![1]
        }
    }
    
    var blueValue: CGFloat {
        get {
            let components = self.cgColor.components
            return components![2]
        }
    }
    
    var alphaValue: CGFloat {
        get {
            return self.cgColor.alpha
        }
    }

    func alpha(_ alpha: CGFloat) -> UIColor {
        return UIColor(red: self.redValue, green: self.greenValue, blue: self.blueValue, alpha: alpha)
    }
    
    func white(_ scale: CGFloat) -> UIColor {
        return UIColor(
            red: self.redValue + (1.0 - self.redValue) * scale,
            green: self.greenValue + (1.0 - self.greenValue) * scale,
            blue: self.blueValue + (1.0 - self.blueValue) * scale,
            alpha: 1.0
        )
    }
}
