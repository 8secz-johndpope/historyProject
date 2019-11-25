//
//  TagPin.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 8/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//


import Foundation

class TagPinView : UIView{
    private final let CoreHeight: CGFloat = 6
    private final let PinAlpha: CGFloat = 0.8
    private final let PinHeight: CGFloat = 4
    var animationCount : Int = 0
    var circleView : CircleOverlayView!
    var circleOverlayView : CircleOverlayView!
    var isAnimating = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        circleView = CircleOverlayView(frame: CGRect(x: (self.width - CoreHeight) / 2, y: (self.width - CoreHeight) / 2, width: CoreHeight, height: CoreHeight))
        circleView.circleLayer.fillColor = UIColor.primary1().cgColor
        addSubview(circleView)
        circleOverlayView = CircleOverlayView(frame: CGRect(x: (self.width - PinHeight) / 2, y: (self.width - PinHeight) / 2, width: PinHeight, height: PinHeight))
        circleOverlayView.alpha = 0.0
        circleOverlayView.circleLayer.fillColor = UIColor.primary1().cgColor
        addSubview(circleOverlayView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimation() {
        self.boomAnimation()
    }
    
    func stopAnimation() {
        self.isAnimating = false
        self.circleOverlayView.layer.removeAllAnimations()
    }
    
    func makeBoom(_ startTime: Double, relativeDuration: Double, alpha: CGFloat, scale: CGFloat){
        UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: relativeDuration, animations: {
            self.circleOverlayView.transform =  CGAffineTransform(scaleX: scale, y: scale)
            self.circleOverlayView.alpha = alpha
        })
    }
    
    func boomAnimation()
    {
        isAnimating = true
        self.circleOverlayView.alpha = PinAlpha
        self.circleOverlayView.transform =  CGAffineTransform(scaleX: 1.0, y: 1.0)
        
        UIView.animateKeyframes(withDuration: 2.0, delay: 0, options: .repeat, animations: {
            
            self.makeBoom(0, relativeDuration: 0.5, alpha: 0.0, scale: 5.0)
            self.makeBoom(0.5, relativeDuration: 0.0, alpha: 1.0, scale: 1.0)
            self.makeBoom(0.6, relativeDuration: 0.5, alpha: 0.0, scale: 5.0)
            
            }, completion: { success in
                self.isAnimating = false
                Log.debug("Animation Tag Pin Complete")
        })
        
        
    }
}
