//
//  VisualEffectView.swift
//  VisualEffectView
//
//  Created by Lasha Efremidze on 5/26/16.
//  Copyright © 2016 Lasha Efremidze. All rights reserved.
//

import UIKit

open class VisualEffectView: UIVisualEffectView {
    
    let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
    
    /// Tint color.
    open var colorTint: UIColor {
        get { return _valueForKey("colorTint") as! UIColor }
        set { _setValue(newValue, forKey: "colorTint") }
    }
    
    /// Tint color alpha.
    open var colorTintAlpha: CGFloat {
        get { return _valueForKey("colorTintAlpha") as! CGFloat }
        set { _setValue(newValue, forKey: "colorTintAlpha") }
    }
    
    /// Blur radius.
    open var blurRadius: CGFloat {
        get { return _valueForKey("blurRadius") as! CGFloat }
        set { _setValue(newValue, forKey: "blurRadius") }
    }
    
    /// Scale factor.
    open var scale: CGFloat {
        get { return _valueForKey("scale") as! CGFloat }
        set { _setValue(newValue, forKey: "scale") }
    }
    
}
extension VisualEffectView {
    func _valueForKey(_ key: String) -> Any? {
        return blurEffect.value(forKeyPath: key)
    }
    
    func _setValue(_ value: Any?, forKey key: String) {
        blurEffect.setValue(value, forKeyPath: key)
        self.effect = blurEffect
    }
    
    func tint(_ color: UIColor, blurRadius: CGFloat) {
        self.colorTint = color
        self.colorTintAlpha = 0.25
        self.blurRadius = blurRadius
        self.scale = 1
    }
}
