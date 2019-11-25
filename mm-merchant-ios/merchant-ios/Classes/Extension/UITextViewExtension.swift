//
//  UITextViewExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 4/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

extension UITextView{
    func format(){
        self.layer.borderColor = UIColor.secondary1().cgColor
        self.layer.borderWidth = Constants.TextField.BorderWidth
//        let paddingView = UIView(frame: CGRect(x:0, y: 0, width: Constants.TextField.LeftPaddingWidth, height: self.frame.height))
//        self.leftView = paddingView
//        self.leftViewMode = UITextFieldViewMode.Always
    }
    
    func fitHeight(){
        var newFrame = self.frame
        newFrame.size.height = self.contentSize.height
        self.frame = newFrame
    }
    
    
    func shouldHighlight(_ isHighLight: Bool) {
        
        if isHighLight {
            
            setBorderCustomize()
            
        } else {
            
            removeHighlight()
            
         }
    }
    
    func setStyleDefault() {
        
        removeHighlight()
        
    }
    
    func setBorderCustomize() {
        
        let borderTF = UIView()
        borderTF.frame = CGRect(x: 1, y: 1, width: self.frame.width - 2, height: self.frame.height - 2)
        self.addSubview(borderTF)
        borderTF.layer.borderColor = UIColor.primary1().cgColor
        borderTF.layer.borderWidth = 1
        borderTF.tag = Constants.TextView.OverlayTag
        borderTF.backgroundColor = UIColor.clear
        borderTF.isUserInteractionEnabled = false
        
    }
    
    func removeHighlight() {
        
        if let borderTF = self.viewWithTag(Constants.TextView.OverlayTag) {
            borderTF.removeFromSuperview()
        }
    }
}
