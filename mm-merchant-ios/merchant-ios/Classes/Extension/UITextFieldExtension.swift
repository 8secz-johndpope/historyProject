//
//  UITextFieldExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 15/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

enum StyleTextField {
    case error
    case success
}

extension UITextField {
    

    func format() {
        self.layer.borderColor = UIColor.secondary1().cgColor
        self.layer.borderWidth = Constants.TextField.BorderWidth
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: Constants.TextField.LeftPaddingWidth, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = UITextFieldViewMode.always
        self.font = UIFont(name: self.font!.fontName, size: CGFloat(14))
        self.textColor = UIColor.secondary2()
        
    }
    
    func formatSize(_ size: CGFloat) {
        format()
        self.font = UIFont(name: self.font!.fontName, size: size)
    }
    
    func noBorderFormatWithSize(_ size: CGFloat) {
        format()
        self.layer.borderWidth = 0
        self.font = UIFont(name: self.font!.fontName, size: size)
    }
    
    func formatTransparent() {
        format()
        self.layer.borderWidth = 0
    }
    
    func formatTransparentValidate() {
        format()
        self.layer.borderWidth = 0
    }
    
    func setStyleDefault(){
        
        self.layer.borderColor = UIColor.secondary1().cgColor
        removeHighlight()
    }
    
    func shouldHighlight(_ isHighlight: Bool, isAddBorderView: Bool? = nil) {
        
        let isAddView = isAddBorderView ?? false
        if isHighlight {
            
            
            
            if isAddView {
                setBorderCustomize()
            } else {
                self.layer.borderColor = UIColor.primary1().cgColor
            }
            
            
        } else {
            
            if isAddView {
                removeHighlight()
            } else {
                self.layer.borderColor = UIColor.secondary1().cgColor
            }
            
        }
        
    }
    
    func setBorderCustomize() {
        
        let borderTF = UITextField()
        borderTF.frame = CGRect(x: 1, y: 1, width: self.frame.width - 2, height: self.frame.height - 2)
        self.addSubview(borderTF)
        borderTF.layer.borderColor = UIColor.primary1().cgColor
        borderTF.layer.borderWidth = 1
        borderTF.tag = Constants.TextField.OverlayTag
        borderTF.isUserInteractionEnabled = false
        
    }
    
    func removeHighlight() {
        
        if let borderTF = self.viewWithTag(Constants.TextField.OverlayTag) {
            borderTF.removeFromSuperview()
        }
    }

    

}
