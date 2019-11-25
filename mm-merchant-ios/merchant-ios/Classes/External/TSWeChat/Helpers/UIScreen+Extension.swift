//
//  UIScreen+Extension.swift
//  TSWeChat
//
//  Created by Hilen on 11/3/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation

public extension UIScreen {
    
    class var orientationSize: CGSize {
        let size = UIScreen.main.bounds.size
        let systemVersion = (UIDevice.current.systemVersion as NSString).floatValue
        let isLand: Bool = UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)
        return (systemVersion > 8.0 && isLand) ? UIScreen.SwapSize(size) : size
    }
    
    class var orientationWidth: CGFloat {
        return self.orientationSize.width
    }
    
    class var orientationHeight: CGFloat {
        return self.orientationSize.height
    }
    
    class var DPISize: CGSize {
        let size: CGSize = UIScreen.main.bounds.size
        let scale: CGFloat = UIScreen.main.scale
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
    
    class func SwapSize(_ size: CGSize) -> CGSize {
        return CGSize(width: size.height, height: size.width)
    }
}



