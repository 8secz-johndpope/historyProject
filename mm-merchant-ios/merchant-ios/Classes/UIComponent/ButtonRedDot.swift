//
//  ButtonRedDot.swift
//  merchant-ios
//
//  Created by HungPM on 1/29/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import UIKit

let RedDotAnimationNotification = "RedDotAnimationNotification"

class ButtonRedDot : UIButton {
    
    private let redDot = UIImageView()
    private var badgeLabel: UILabel?
    
    var redDotAdjust: CGPoint = CGPoint(x: -10, y: 0)
    var badgeAdjust: CGPoint = CGPoint(x: -10, y: -10)
    
    override var frame : CGRect {
        didSet {
            let frameRedDot = CGRect(x: frame.width + redDotAdjust.x, y: redDotAdjust.y, width: 8, height: 8)
            redDot.frame = frameRedDot
            
            if let label = badgeLabel {
                let frameBadge = CGRect(x: frame.width + badgeAdjust.x, y: badgeAdjust.y, width: 15, height: 15)
                label.frame = frameBadge
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initsubviews()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ButtonRedDot.animateRedDot),
            name: NSNotification.Name(rawValue: RedDotAnimationNotification),
            object: nil
        )
    }
    
    init(number: Int) {
        super.init(frame: CGRect.zero)
        
        initsubviews()
        
        badgeLabel = { () -> UILabel in
            let frameBadge = CGRect(x: frame.width + badgeAdjust.x, y: badgeAdjust.y, width: 15, height: 15)

            let label = UILabel(frame: frameBadge)
            label.round()
            label.font = UIFont.systemFont(ofSize: 12)
            label.numberOfLines = 1
            label.textAlignment = .center
            label.backgroundColor = UIColor.primary1()
            label.textColor = UIColor.white
            label.text = String(number)
            label.isHidden = number > 0 ? false : true
            
            let circleLayer = CAShapeLayer()
            circleLayer.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: label.width, height: label.width)).cgPath
            circleLayer.fillColor = UIColor.clear.cgColor
            circleLayer.strokeColor = UIColor.white.cgColor
            circleLayer.lineWidth = 1
            label.layer.addSublayer(circleLayer)
            addSubview(label)

            return label
        }()
        
    }
    
    private func initsubviews() {
        let frameRedDot = CGRect(x: frame.width + redDotAdjust.x, y: redDotAdjust.y, width: 8, height: 8)
        redDot.frame = frameRedDot
        redDot.clipsToBounds = true
        redDot.alpha = 0
        redDot.backgroundColor = UIColor.red
        redDot.round()
        
        addSubview(redDot)
    }
    
    func setBadgeNumber(_ count: Int) {
        guard let label = badgeLabel else { return }
        
        if count > 0 {
            if count > 9 {
                label.font = UIFont.systemFont(ofSize: 8)
            }
            else {
                label.font = UIFont.systemFont(ofSize: 12)
            }
            
            if count > 99 {
                label.adjustsFontSizeToFitWidth = true
            }
            else {
                label.adjustsFontSizeToFitWidth = false
            }
            label.isHidden = false
            label.text = count > 99 ? "99+" : String(count)
        } else {
            label.isHidden = true
        }
    }

    func redDotCenter() -> CGPoint {
        return redDot.center
    }
    
    func redDotSize() -> CGSize {
        return redDot.bounds.size
    }
    
    func hasRedDot(_ value: Bool) {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            if value {
                self.redDot.alpha = 1
            } else {
                self.redDot.alpha = 0
            }
        }) 
    }
    
    @objc func animateRedDot() {
        
        self.redDot.alpha = 1
        
        let animationDuration = TimeInterval(0.2)
        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: .curveEaseOut,
            animations: { () -> Void in
                self.redDot.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
            },
            completion: { (success) -> Void in
                UIView.animate(
                    withDuration: animationDuration,
                    delay: 0,
                    options: .curveEaseIn,
                    animations: { () -> Void in
                        self.redDot.transform = CGAffineTransform.identity
                    },
                    completion: { (success) -> Void in
                        
                    }
                )
            }
        )
    }
    
    func animateHeartIcon() {
        
        let redButton = UIButton(type: .custom)
        let duration = TimeInterval(0.2)
        
        let prepareAnimation = {
            
            redButton.frame = self.bounds
            redButton.setImage(UIImage(named: "icon_heart_filled"), for: UIControlState())
            redButton.alpha = 0.0
            self.addSubview(redButton)
        }
        prepareAnimation()
        
        let step2 = {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: .curveEaseIn,
                animations: { () -> Void in
                    redButton.alpha = 1.0
                    redButton.transform = CGAffineTransform.identity
                },
                completion: { (success) -> Void in
                    redButton.removeFromSuperview()
                }
            )
        }
        
        let step1 = {
            UIView.animate(
                withDuration: duration,
                delay: 0,
                options: .curveEaseOut,
                animations: { () -> Void in
                    redButton.alpha = 0.5
                    redButton.transform = CGAffineTransform.identity.scaledBy(x: 1.7, y: 1.7)
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
}
