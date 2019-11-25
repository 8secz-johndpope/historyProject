//
//  WishListAnimation.swift
//  merchant-ios
//
//  Created by HungPM on 2/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class WishListAnimation {
    
    private var heartImage : UIImageView?
    private var redDotButton : ButtonRedDot?
    private var isAnimate = false
    private lazy var animationImage = UIImage(named: "like_on")
    
    init() {}
    
    convenience init(heartImage : UIImageView, redDotButton: ButtonRedDot?) {
        self.init()
        
        self.redDotButton = redDotButton
        self.heartImage = heartImage
    }
    
    func setAnimationImage(_ image: UIImage?){
        self.animationImage = image
    }
    
    
    func showAnimation(completion complete : (() -> Void)? = nil) {
        
        if (!isAnimate){
            isAnimate = true
            if let redDotButton = self.redDotButton {
                redDotButton.animateHeartIcon()
            } else {
                ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
            }
            
            guard let _heartImage = self.heartImage else { return }
            
            let redHeartImage = UIImageView(frame: _heartImage.bounds)
            redHeartImage.contentMode = .scaleAspectFit
            
            let prepareAnimation = {
                redHeartImage.image = self.animationImage
                redHeartImage.alpha = 0.0
                if let _ = self.heartImage {
                    self.heartImage?.addSubview(redHeartImage)
                }
                
            }
            prepareAnimation()
            
            let duration = TimeInterval(0.2)
            
            let step2 = {
                UIView.animate(
                    withDuration: duration,
                    delay: 0,
                    options: .curveEaseIn,
                    animations: { () -> Void in
                        redHeartImage.alpha = 1.0
                        redHeartImage.transform = CGAffineTransform.identity
                    },
                    completion: { (success) -> Void in
                        redHeartImage.removeFromSuperview()
                        
                        if let completeAction = complete {
                            self.isAnimate = false
                            self.heartImage = nil
                            completeAction()
                            
                        }
                    }
                )
            }
            
            let step1 = {
                UIView.animate(
                    withDuration: duration,
                    delay: 0,
                    options: .curveEaseOut,
                    animations: { () -> Void in
                        redHeartImage.alpha = 0.5
                        redHeartImage.transform = CGAffineTransform.identity.scaledBy(x: 1.7, y: 1.7)
                    },
                    completion: { (success) -> Void in
                        step2()
                    }
                )
            }
            step1()
        }
        
    }
    
    func showAnimationforsmallimage(completion complete : (() -> Void)? = nil) {
        if let redDotButton = self.redDotButton {
            redDotButton.animateHeartIcon()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
        
        guard let _heartImage = self.heartImage else { return }
        
        let redHeartImage = UIImageView(frame: _heartImage.bounds)
        redHeartImage.contentMode = .scaleAspectFit
        
        let prepareAnimation = {
            redHeartImage.image = UIImage(named: "star_red")
            redHeartImage.alpha = 0.0
            self.heartImage?.addSubview(redHeartImage)
        }
        prepareAnimation()
        
        let duration = TimeInterval(0.2)
        
        let step2 = {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: .curveEaseIn,
                animations: { () -> Void in
                    redHeartImage.alpha = 1.0
                    redHeartImage.transform = CGAffineTransform.identity
                },
                completion: { (success) -> Void in
                    redHeartImage.removeFromSuperview()
                    
                    if let completeAction = complete {
                        completeAction()
                    }
                }
            )
        }
        
        let step1 = {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: .curveEaseOut,
                animations: { () -> Void in
                    redHeartImage.alpha = 0.5
                    redHeartImage.transform = CGAffineTransform.identity.scaledBy(x: 3, y: 3)
                },
                completion: { (success) -> Void in
                    step2()
                }
            )
        }
        step1()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
