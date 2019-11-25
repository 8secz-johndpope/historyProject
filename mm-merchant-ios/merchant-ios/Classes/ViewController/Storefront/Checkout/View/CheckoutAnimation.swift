//
//  CheckoutAnimation.swift
//  merchant-ios
//
//  Created by HungPM on 2/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CheckoutAnimation : UIView {
    
    private var selectedColorImageView : UIImageView!
    private var itemStartPos : CGPoint!
    private var itemSize : CGSize!
    private var redDotButton : ButtonRedDot?
    var PDPCartAnimation:Bool = false
    convenience init(
        itemImage : UIImage,
        itemSize: CGSize,
        itemStartPos: CGPoint,
        redDotButton: ButtonRedDot?
        ) {
            
            self.init(frame: UIScreen.main.bounds)
            
            self.redDotButton = redDotButton
            self.itemSize = itemSize
            self.itemStartPos = itemStartPos
            
            let frame = CGRect(
                x: self.itemStartPos.x - self.itemSize.width / 2,
                y: self.itemStartPos.y - self.itemSize.height / 2,
                width: self.itemSize.width,
                height: self.itemSize.height
            )
            
            let imageView = UIImageView(frame: frame)
            imageView.image = itemImage
            imageView.viewBorder()
            imageView.round()
            
            self.selectedColorImageView = UIImageView(frame: frame)
            self.selectedColorImageView.image = imageView.imageValue()
            
    }
    
    func frameFromCenter(_ center: CGPoint, width: CGFloat, height: CGFloat) -> CGRect {
        let halfWidth = width / 2
        let halfHeight = height / 2
        
        return CGRect(x: center.x - halfWidth, y: center.y - halfHeight, width: width, height: height)
    }
    
    func showAnimation() {
        
        if let redDotButton = self.redDotButton {
            let prepareAnimation = {
                
                let initRatio = CGFloat(0.5)
                
                self.selectedColorImageView.alpha = 0.5
                self.selectedColorImageView.frame = self.frameFromCenter(
                    self.itemStartPos,
                    width: self.itemSize.width * initRatio,
                    height: self.itemSize.height * initRatio
                )
                
                self.addSubview(self.selectedColorImageView)
            }
            prepareAnimation()
            
            let step3 = {
                
//                var destPoint = redDotButton.convert(redDotButton.redDotCenter(), to: self)
                var destPoint = CGPoint(x: self.itemStartPos.x - ScreenWidth * 0.5, y: self.itemStartPos.y)
                if self.PDPCartAnimation {
                   destPoint = CGPoint(x: self.itemStartPos.x - ScreenWidth * 0.35, y: self.itemStartPos.y)
                }
                let targetFrame = self.frameFromCenter(destPoint, width: redDotButton.redDotSize().width, height: redDotButton.redDotSize().height)
                
                UIView.animate(withDuration: 0.3, delay: 0,
                    options: .curveEaseIn,
                    animations: { () -> Void in
                        self.selectedColorImageView.frame = targetFrame
                        self.selectedColorImageView.alpha = 0.3
                    },
                    completion: { (success) -> Void in
                        self.redDotButton?.setBadgeNumber(CacheManager.sharedManager.numberOfCartItems())
                        self.removeFromSuperview()
                    }
                )
            }
            
            let step2 = {
                
                let initRatio = CGFloat(0.8)
                let moveUpDelta = CGFloat(80)
                var startPoint = self.selectedColorImageView.center.x - ScreenWidth * 0.2
                if self.PDPCartAnimation {
                    startPoint = self.selectedColorImageView.center.x - ScreenWidth * 0.1
                }
                let targetCenter = CGPoint(x: startPoint, y: self.selectedColorImageView.center.y - moveUpDelta)
                let targetFrame = self.frameFromCenter(targetCenter, width: self.itemSize.width * initRatio, height: self.itemSize.height * initRatio)
                
                UIView.animate(withDuration: 0.25, delay: 0,
                    options: .curveLinear,
                    animations: { () -> Void in
                        self.selectedColorImageView.frame = targetFrame
                    },
                    completion: { (success) -> Void in
                        step3()
                    }
                )
                
            }
            
            let step1 = {
                
                let moveUpDelta = CGFloat(30)
                var startPoint = self.itemStartPos.x - ScreenWidth * 0.2
                if self.PDPCartAnimation {
                    startPoint = self.itemStartPos.x - ScreenWidth * 0.1
                }
                let targetCenter = CGPoint(x: startPoint, y: self.itemStartPos.y - moveUpDelta)
                let targetFrame = self.frameFromCenter(targetCenter, width: self.itemSize.width, height: self.itemSize.height)
                
                UIView.animate(withDuration: 0.15, delay: 0,
                    options: .curveLinear,
                    animations: { () -> Void in
                        self.selectedColorImageView.alpha = 1
                        self.selectedColorImageView.frame = targetFrame
                    },
                    completion: { (success) -> Void in
                        step2()
                    }
                )
                
            }
            
            step1()
        }
    }
    
    func showAnimationTwo() {
        
        if let redDotButton = self.redDotButton {
            let prepareAnimation = {
                
                let initRatio = CGFloat(0.5)
                
                self.selectedColorImageView.alpha = 0.5
                self.selectedColorImageView.frame = self.frameFromCenter(
                    self.itemStartPos,
                    width: self.itemSize.width * initRatio,
                    height: self.itemSize.height * initRatio
                )
                
                self.addSubview(self.selectedColorImageView)
            }
            prepareAnimation()
            
            let step3 = {
                
//                let destPoint = redDotButton.convert(redDotButton.redDotCenter(), to: self)
                let targetCenter = CGPoint(x: self.itemStartPos.x - ScreenWidth * 0.6, y: self.itemStartPos.y)
                let targetFrame = self.frameFromCenter(targetCenter, width: redDotButton.redDotSize().width, height: redDotButton.redDotSize().height)
                
                UIView.animate(withDuration: 0.3, delay: 0,
                               options: .curveEaseIn,
                               animations: { () -> Void in
                                self.selectedColorImageView.frame = targetFrame
                                self.selectedColorImageView.alpha = 0.3
                },
                               completion: { (success) -> Void in
                                self.redDotButton?.setBadgeNumber(CacheManager.sharedManager.numberOfCartItems())
                                self.removeFromSuperview()
                }
                )
            }
            
            let step2 = {
                
                let initRatio = CGFloat(0.8)
                let moveUpDelta = CGFloat(80)
                let targetCenter = CGPoint(x: self.selectedColorImageView.center.x, y: self.selectedColorImageView.center.y - moveUpDelta)
                let targetFrame = self.frameFromCenter(targetCenter, width: self.itemSize.width * initRatio, height: self.itemSize.height * initRatio)
                
                UIView.animate(withDuration: 0.25, delay: 0,
                               options: .curveLinear,
                               animations: { () -> Void in
                                self.selectedColorImageView.frame = targetFrame
                },
                               completion: { (success) -> Void in
                                step3()
                }
                )
                
            }
            
            let step1 = {
                
                let moveUpDelta = CGFloat(30)
                let targetCenter = CGPoint(x: self.itemStartPos.x, y: self.itemStartPos.y - moveUpDelta)
                let targetFrame = self.frameFromCenter(targetCenter, width: self.itemSize.width, height: self.itemSize.height)
                
                UIView.animate(withDuration: 0.15, delay: 0,
                               options: .curveLinear,
                               animations: { () -> Void in
                                self.selectedColorImageView.alpha = 1
                                self.selectedColorImageView.frame = targetFrame
                },
                               completion: { (success) -> Void in
                                step2()
                }
                )
                
            }
            
            step1()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
