//
//  SwipeAnimatingView.swift
//  merchant-ios
//
//  Created by Alan YU on 21/2/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class SwipeAnimatingView: UIView {
    
    private enum AnimationState: Int {
        case idle
        case prepare
        case fadeIn
        case fadeOut
        case maskIn
        case maskOut
    }
    
    private enum AnimationError: Int {
        case fail = 1
        case forceStop = 2
        case staticTextExists = 3
    }
    
    private static let EffectImage = UIImage(named: "swipePay_effect")
    private static let FadeAreWidth = CGFloat(30)
    private static let AnimationFailError = NSError(domain: "com.mymm.Animation", code: AnimationError.fail.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: "Animation failed."])
    private static let AnimationStoppedError = NSError(domain: "com.mymm.Animation", code: AnimationError.forceStop.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: "Animation stopped."])
    private static let AnimationStaticExistsError = NSError(domain: "com.mymm.Animation", code: AnimationError.staticTextExists.rawValue, userInfo: [NSLocalizedFailureReasonErrorKey: "Animation static text exists."])
    
    private var imageEffectView: UIImageView = {
        var imageView = UIImageView(frame: CGRect.zero)
        imageView.image = SwipeAnimatingView.EffectImage
        return imageView
    } ()
    
    private var shouldAnimate = false {
        didSet {
            if shouldAnimate {
                self.animate()
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            label.frame = bounds
            imageEffectView.transform = CGAffineTransform.identity
            imageEffectView.frame = UIEdgeInsetsInsetRect(bounds, UIEdgeInsets(top: 0, left: -SwipeAnimatingView.FadeAreWidth, bottom: 0, right: -SwipeAnimatingView.FadeAreWidth))
        }
    }
    
    var fadingText: NSAttributedString? {
        didSet {
            if state == .idle || state == .fadeIn || state == .fadeOut {
                label.attributedText = fadingText
            }
        }
    }
    var maskingText: NSAttributedString? {
        didSet {
            if state == .maskIn || state == .maskOut {
                label.attributedText = maskingText
            }
        }
    }
    var staticText: NSAttributedString? {
        didSet {
            displayStaticText()
        }
    }
    
    private var state = AnimationState.idle
    private var label: UILabel = {
        let label = UILabel()
        label.minimumScaleFactor = 0.5
        label.formatSingleLine(15)
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        label.textColor = UIColor.secondary2()
        return label
    } ()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        clipsToBounds = true
        
        addSubview(label)
        addSubview(imageEffectView)
        
        defaultSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func defaultSetup() {
        label.alpha = 1
        imageEffectView.alpha = 0
    }
    
    private func animationConditionCheck() -> NSError? {
        if staticText != nil {
            return SwipeAnimatingView.AnimationStaticExistsError
        }
        
        if !shouldAnimate {
            return SwipeAnimatingView.AnimationStoppedError
        }
        
        return nil
    }
    
    private func fadeOut() -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            
            if let error = animationConditionCheck() {
                reject(error)
                return
            }
            
            state = .fadeOut
            defaultSetup()
            
            label.attributedText = self.fadingText
            
            UIView.animate(withDuration: 
                1.0,
                delay: 2.0,
                options: .curveEaseInOut,
                animations: {
                    self.label.alpha = 0
                },
                completion: { success in
                    if success {
                        fulfill(())
                    } else {
                        reject(SwipeAnimatingView.AnimationFailError)
                    }
                }
            )
        }
    }
    
    private func fadeIn() -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            
            if let error = animationConditionCheck() {
                reject(error)
                return
            }
            
            state = .fadeIn
            defaultSetup()
            
            label.alpha = 0
            label.attributedText = fadingText
            
            UIView.animate(withDuration: 
                1.0,
                delay: 0.0,
                options: .curveEaseInOut,
                animations: {
                    self.label.alpha = 1
                },
                completion: { success in
                    if success {
                        fulfill(())
                    } else {
                        reject(SwipeAnimatingView.AnimationFailError)
                    }
                }
            )
        }
    }
    
    private func maskIn() -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            
            if let error = animationConditionCheck() {
                reject(error)
                return
            }
            
            state = .maskIn
            defaultSetup()
            
            imageEffectView.alpha = 1
            imageEffectView.transform = CGAffineTransform.identity
            label.attributedText = maskingText
            
            UIView.animate(withDuration: 
                2.0,
                delay: 0.2,
                options: .curveEaseInOut,
                animations: {
                    self.imageEffectView.transform = CGAffineTransform(translationX: self.imageEffectView.frame.width - SwipeAnimatingView.FadeAreWidth, y: 0)
                },
                completion: { success in
                    if success {
                        fulfill(())
                    } else {
                        reject(SwipeAnimatingView.AnimationFailError)
                    }
                }
            )
        }
    }
    
    private func maskOut() -> Promise<Void> {
        return Promise<Void> { fulfill, reject in
            
            if let error = animationConditionCheck() {
                reject(error)
                return
            }
            
            state = .maskOut
            defaultSetup()
            
            imageEffectView.alpha = 1
            imageEffectView.transform = CGAffineTransform.identity.translatedBy(x: -self.imageEffectView.frame.width, y: 0)
            label.attributedText = maskingText
            
            UIView.animate(withDuration: 
                2.0,
                delay: 0.2,
                options: .curveEaseInOut,
                animations: {
                    self.imageEffectView.transform = CGAffineTransform.identity
                },
                completion: { success in
                    if success {
                        fulfill(())
                    } else {
                        reject(SwipeAnimatingView.AnimationFailError)
                    }
                }
            )
        }
    }
    
    private func displayStaticText() {
        defaultSetup()
        
        label.attributedText = staticText
    }
    
    func animate() {
        
        if state != .idle || !shouldAnimate || staticText != nil {
            return
        }
        
        state = .prepare
        
        Log.debug("SwipeAnimatingView animating \(Unmanaged.passUnretained(self).toOpaque())")
        
        firstly { () -> Promise<Void> in
            
            return fadeOut()
            
        }.then { () -> Promise<Void> in
            
            return self.maskIn()
            
        }.then { () -> Promise<Void> in
            
            return self.maskOut()
            
        }.then { () -> Promise<Void> in
            
            return self.fadeIn()
            
        }.then { () -> Void in
            
            self.state = .idle
            self.animate()
            
        }.catch { error -> Void in
            
            // Errors are expected but need to keep an eye on how frequency the error show up
            Log.debug("Animation error : \(error)")
            
            self.state = .idle
            
            if error._code == AnimationError.fail.rawValue {
                self.animate()
            }
            
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // if new window is nil mean not visible to user
        shouldAnimate = (window != nil)
        
    }
    
    deinit {
        Log.debug("SwipeAnimatingView deinit \(Unmanaged.passUnretained(self).toOpaque())")
    }
}
