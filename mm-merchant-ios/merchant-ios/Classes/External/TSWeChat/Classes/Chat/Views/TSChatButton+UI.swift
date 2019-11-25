//
//  TSChatButton+UI.swift
//  TSWeChat
//
//  Created by Hilen on 12/30/15.
//  Copyright © 2015 Hilen. All rights reserved.
//

import Foundation

// MARK: - @extension TSChatButton
extension UIButton {
    var animationViewTag: Int { return 99 }
    /**
     控制——切换声音按钮和键盘切换的图标变化
     
     - parameter showKeyboard: 是否显示键盘
     */
    func emotionSwiftVoiceButtonUI(showKeyboard: Bool) {
        if showKeyboard {
            self.setImage(TSAsset.Tool_keyboard_1.image, for: UIControlState())
            self.setImage(TSAsset.Tool_keyboard_2.image, for: .highlighted)
        } else {
            self.setImage(TSAsset.Tool_voice_1.image, for: UIControlState())
            self.setImage(TSAsset.Tool_voice_2.image, for: .highlighted)
        }
    }
    
    /**
     控制——表情按钮和键盘切换的图标变化
     
     - parameter showKeyboard: 是否显示键盘
     */
    func replaceEmotionButtonUI(showKeyboard: Bool) {
        if showKeyboard {
            self.setImage(TSAsset.Tool_keyboard_1.image, for: UIControlState())
            self.setImage(TSAsset.Tool_keyboard_2.image, for: .highlighted)
        } else {
            self.setImage(TSAsset.Tool_emotion_1.image, for: UIControlState())
            self.setImage(TSAsset.Tool_emotion_2.image, for: .highlighted)
        }
    }
    
    /**
     控制--声音按钮的 UI 切换
     
     - parameter isRecording: 是否开始录音
     */
//    func updateMetraAnimation(metra: Float) {
//        let scaleAnimation:CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
//        
//        scaleAnimation.duration = 0.5
//        scaleAnimation.repeatCount = 1
//        scaleAnimation.autoreverses = true
//        let minMetra: Float = min(metra, 1.0)
//        scaleAnimation.fromValue = 0.8+minMetra
//        scaleAnimation.toValue = 0.4
//        
//        self.animatingView().layer.addAnimation(scaleAnimation, forKey: "scale")
//    }
    
    func addOnRecordButtonAnimation(isRecording: Bool) {
        if isRecording {
            self.addAnimationView()
            self.startAnimation()
        } else {
            self.stopAnimation()
        }
    }
    
    func addAnimationView() {
        let view: UIView = self.animatingView()
        view.frame = CGRect(x: 0, y: 0, width: self.frame.size.width*2, height: self.frame.size.height*2)
        view.layer.cornerRadius = 50
        view.backgroundColor = UIColor.red
        view.center = self.center
        view.alpha = 0.1
        view.tag = animationViewTag
        self.superview?.addSubview(view)
    }
    
    func startAnimation() {
        let scaleAnimation:CABasicAnimation = CABasicAnimation(keyPath: "transform.scale")
        
        scaleAnimation.duration = 0.5
        scaleAnimation.repeatCount = Float.infinity
        scaleAnimation.autoreverses = true
        scaleAnimation.fromValue = 1.2;
        scaleAnimation.toValue = 0.4;
        
        self.animatingView().layer.add(scaleAnimation, forKey: "scale")
    }
    
    func stopAnimation() {
        self.animatingView().removeFromSuperview()
    }
    
    fileprivate func getChatActionBar() -> TSChatActionBarView? {
        
        //线上查找
        var view = self.superview
        for _ in 0..<2 {
            if let v = view as? TSChatActionBarView {
                return v
            }
            view = view?.superview
        }
        
        return nil
    }
    
    func animatingView() -> UIView {
        if let v = getChatActionBar() {
            
            if v.animatingView == nil {
                v.animatingView = UIView()
            }
            return v.animatingView!
        } else {
            return UIView()
        }
    }
    
}


