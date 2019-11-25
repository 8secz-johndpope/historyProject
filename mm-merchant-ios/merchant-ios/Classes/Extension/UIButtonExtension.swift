//
//  UIButtonExtension.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 15/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import UIKit

var ActionBlockKey: UInt8 = 0

typealias UIButtonActionClosure = (_ sender: UIButton) -> Void

class UIButtonClosureWrapper {
    var closure: UIButtonActionClosure?
    init(_ closure: UIButtonActionClosure?) {
        self.closure = closure
    }
}

extension UIButton {
    
    var touchUpClosure: UIButtonActionClosure? {
        get {
            if let closure = objc_getAssociatedObject(self, &ActionBlockKey) as? UIButtonClosureWrapper {
                return closure.closure
            }
            return nil
        }
        set {
            self.addTarget(self, action: #selector(UIButton.UIButtonActionHandler), for: .touchUpInside)
            objc_setAssociatedObject(
                self,
                &ActionBlockKey,
                UIButtonClosureWrapper(newValue),
                objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    @objc func UIButtonActionHandler(_ button: UIButton) {
        if let callback = self.touchUpClosure {
            callback(self)
        }
    }
    
    //MARK: - Format
    func formatPrimary(){
        self.layer.cornerRadius = Constants.Button.Radius
        self.layer.backgroundColor = UIColor.primary1().cgColor
        self.setTitleColor(UIColor.white, for: UIControlState())
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
    }
    
    func formatWeChat(){
        self.layer.cornerRadius = Constants.Button.Radius
        self.layer.backgroundColor = UIColor.wechatButtonColor().cgColor
        self.setTitleColor(UIColor.white, for: UIControlState())
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
    }
    
    func formatPrimaryDiable(){
        self.layer.cornerRadius = Constants.Button.Radius
        self.layer.borderWidth = Constants.Button.BorderWidth
        self.layer.borderColor = UIColor.primary1().cgColor
        self.layer.backgroundColor = UIColor.clear.cgColor
        self.setTitleColor(UIColor.primary1(), for: UIControlState())
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
    }
    
    func formatSecondary(titleColor: UIColor? = UIColor.secondary2()){
        self.layer.borderWidth = Constants.Button.BorderWidth
        self.layer.borderColor = UIColor.secondary1().cgColor
        self.layer.cornerRadius = Constants.Button.Radius
        self.layer.backgroundColor = UIColor.white.cgColor
        self.setTitleColor(titleColor, for: UIControlState())
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
    }
    
    func formatSecondaryNonBorder(){
        self.layer.backgroundColor = UIColor.white.cgColor
        self.setTitleColor(UIColor.secondary2(), for: UIControlState())
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
    }
    
    func formatTransparent(){
        self.layer.borderWidth = Constants.Button.BorderWidth
        self.layer.borderColor = UIColor.secondary3().cgColor
        self.layer.cornerRadius = Constants.Button.Radius
        self.layer.backgroundColor = UIColor.clear.cgColor
        self.setTitleColor(UIColor.secondary3(), for: UIControlState())
        
        if let titleLabel = self.titleLabel, let font = UIFont(name: titleLabel.font.fontName, size: CGFloat(14)) {
            titleLabel.font = font
        }
    }
    
    func formatWhite(){
        self.layer.backgroundColor = UIColor.white.cgColor
        self.setTitleColor(UIColor.primary1(), for: UIControlState())
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
    }
    
    func formatDisable() {
        self.layer.cornerRadius = Constants.Button.Radius
        self.layer.backgroundColor = UIColor.secondary1().cgColor
        self.setTitleColor(UIColor.gray, for: UIControlState())
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
    }
    
    func formatDisable(_ titleColor: UIColor) {
        self.layer.cornerRadius = Constants.Button.Radius
        self.layer.backgroundColor = UIColor.secondary1().cgColor
        self.setTitleColor(titleColor, for: UIControlState())
        self.titleLabel!.font = UIFont(name: self.titleLabel!.font.fontName, size: CGFloat(14))!
    }
    
    //MARK: - Config
    func config(normalImage: UIImage?, selectedImage: UIImage?) {
        self.setImage(normalImage, for: UIControlState())
        self.setImage(normalImage, for:  .highlighted)
        self.setImage(selectedImage, for: .selected)
        self.setImage(selectedImage, for: [.selected, .highlighted])
    }
    
    func config(normalBackgroundImage: UIImage?, selectedBackgroundImage: UIImage?) {
        self.setBackgroundImage(normalBackgroundImage, for: UIControlState())
        self.setBackgroundImage(normalBackgroundImage, for: .highlighted)
        self.setBackgroundImage(selectedBackgroundImage, for: .selected)
        self.setBackgroundImage(selectedBackgroundImage, for: [.selected, .highlighted])
    }
    
    //MARK: - Image
    func mm_setImageWithURL(_ URL: URL, forState state: UIControlState,
                            placeholderImage: UIImage?) {
        self.kf.setImage(with: URL, for: state, placeholder: placeholderImage)
    }
    
    func roundCorner(_ radius: CGFloat) {
        self.layer.cornerRadius = radius;
        self.clipsToBounds = true;
    }
    
    func redRoundRectButton() {
        self.roundCorner(self.frame.size.height/2)
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 0.5
        self.titleLabel?.textColor = UIColor.red
        self.backgroundColor = UIColor.white
    }
    
}

extension UIButton {
    public func setIconInLeft(){
        setIconInLeftWithSpacing(0)
    }
    public func setIconInRight(){
        setIconInRightWithSpacing(0)
    }
    public func setIconInTop(){
        setIconInTopWithSpacing(0)
    }
    public func setIconInBottom(){
        setIconInBottomWithSpacing(0)
    }
    
    public func setIconInLeftWithSpacing(_ spacing:CGFloat){
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: spacing / 2, bottom: 0, right: -spacing / 2)
    }
    
    public func setIconInRightWithSpacing(_ spacing:CGFloat){
        
        let img_W = self.imageView?.frame.size.width
        let tit_W = self.titleLabel?.frame.size.width
        
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(img_W! + spacing / 2), bottom: 0, right: (img_W! + spacing / 2))
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: (tit_W! + spacing / 2), bottom: 0, right: -(tit_W! + spacing / 2))
    }
    
    public func setIconInTopWithSpacing(_ spacing:CGFloat){
        let img_W = self.imageView?.frame.size.width
        let img_H = self.imageView?.frame.size.height
        let tit_W = self.titleLabel?.frame.size.width
        let tit_H = self.titleLabel?.frame.size.height
        
        self.titleEdgeInsets = UIEdgeInsets(top: (tit_H! / 2 + spacing / 2), left: -(img_W! / 2), bottom: -(tit_H! / 2 + spacing / 2), right: (img_W! / 2))
        self.imageEdgeInsets = UIEdgeInsets(top: -(img_H! / 2 + spacing / 2), left: (tit_W! / 2), bottom: (img_H! / 2 + spacing / 2), right: -(tit_W! / 2))
    }
    
    public func setIconInBottomWithSpacing(_ spacing:CGFloat){
        let img_W = self.imageView?.frame.size.width
        let img_H = self.imageView?.frame.size.height
        let tit_W = self.titleLabel?.frame.size.width
        let tit_H = self.titleLabel?.frame.size.height
        
        self.titleEdgeInsets = UIEdgeInsets(top: (tit_H! / 2 + spacing / 2), left: -(img_W! / 2), bottom: -(tit_H! / 2 + spacing / 2), right: (img_W! / 2))
        self.imageEdgeInsets = UIEdgeInsets(top: -(img_H! / 2 + spacing / 2), left: (tit_W! / 2), bottom: (img_H! / 2 + spacing / 2), right: -(tit_W! / 2))
    }


}
