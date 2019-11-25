//
//  AnimateLoading.swift
//  merchant-ios
//
//  Created by Jerry Chong on 21/6/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit
import Foundation
import SnapKit

open class LoadingOverlay{
    private var currentViewController: UIViewController?
    private var overlayView = UIView()
    private var loadingIndicator = MMRefreshAnimator()
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 15)
        label.textAlignment = NSTextAlignment.center
        label.text = String.localize("LB_CA_CHECK_OUT_LOADING_1")
        label.sizeToFit()
        label.alpha = 0
        return label
    }()
    
    private let reloadButton: UIButton = {
        let button = UIButton()
        button.isHidden = true
        button.layer.masksToBounds = true
        button.backgroundColor = UIColor.clear
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 2
        button.setTitle(String.localize("LB_AC_CHECK_OUT_REFRESH"), for: UIControlState())
        button.setTitleColor(UIColor.white, for: UIControlState())
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        return button
    }()
    
    private var onetimeTimer: Timer?
    private var oneTime: Double = 2
    private var counterTimer: Timer?
    private var countdownTime: Double = 10
    private var previousNumber = 1

    class var shared: LoadingOverlay {
        struct Static {
            static let instance: LoadingOverlay = LoadingOverlay()
        }
        return Static.instance
    }
    
    open func showOverlay(_ vc: UIViewController!) {
        if counterTimer != nil {
            counterTimer?.invalidate()
            counterTimer = nil
        }
        if onetimeTimer != nil {
            onetimeTimer?.invalidate()
            onetimeTimer = nil
        }
        if let _ = currentViewController {
        }else{
            currentViewController = vc
            overlayView = UIView(frame: vc.view.frame)
            overlayView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
            overlayView.center = vc.view.center
            vc.view.addSubview(overlayView)
            
            overlayView.addSubview(loadingIndicator)
            overlayView.addSubview(messageLabel)
            overlayView.addSubview(reloadButton)
            
            loadingIndicator.isFromCheckout = true
            loadingIndicator.checkoutLoadingSize = 62
            loadingIndicator.snp.makeConstraints { (target) in
                target.width.height.equalTo(62)
                target.center.equalTo(vc.view)
            }
            
            
            messageLabel.snp.makeConstraints { (target) in
                target.height.equalTo(15)
                target.right.equalTo(0)
                target.left.equalTo(0)
                target.top.equalTo(loadingIndicator.snp.bottom).offset(25)
            }
            
            reloadButton.snp.makeConstraints { (target) in
                target.height.equalTo(39)
                target.width.equalTo(94)
                target.centerX.equalToSuperview()
                target.top.equalTo(messageLabel.snp.bottom).offset(25)
                
            }
        }
        
        messageLabel.alpha = 0
        messageLabel.text = String.localize("LB_CA_CHECK_OUT_LOADING_1")
        reloadButton.isHidden = true
        reloadButton.alpha = 0
        reloadButton.addTarget(self, action: #selector(pressUpdateMessage), for: .touchUpInside)
        counterTimer = Timer.scheduledTimer(timeInterval: countdownTime, target: self, selector: #selector(LoadingOverlay.updateMessage), userInfo: nil, repeats: false)
        onetimeTimer = Timer.scheduledTimer(timeInterval: oneTime, target: self, selector: #selector(LoadingOverlay.showMessage), userInfo: nil, repeats: false)
        
        loadingIndicator.animateImageView()
        
    }
    
    open func hideOverlayView() {
        if let _ = currentViewController {
            if counterTimer != nil {
                counterTimer?.invalidate()
                counterTimer = nil
            }
            if onetimeTimer != nil {
                onetimeTimer?.invalidate()
                onetimeTimer = nil
            }

            loadingIndicator.stopAnimateImageView()
            overlayView.removeFromSuperview()
            currentViewController = nil
        }
    }
    
    @objc private func pressUpdateMessage(_ sender: UIButton){
        reloadButton.isHidden = true
        UIView.animate(withDuration: 0.5, animations: {
            self.reloadButton.alpha = 0
        })
        
        counterTimer = Timer.scheduledTimer(timeInterval: countdownTime, target: self, selector: #selector(LoadingOverlay.updateMessage), userInfo: nil, repeats: false)
        
        var randomNumber: Int = random(2, to: 5)
        repeat{
            randomNumber = random(2, to: 5)
            print("randomNumber >> " + randomNumber.description)
        }while (randomNumber == previousNumber)

        previousNumber = randomNumber
        messageLabel.text = String.localize("LB_CA_CHECK_OUT_LOADING_" + randomNumber.description)
        
    }
    
    @objc private func updateMessage() {
        reloadButton.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {
            self.reloadButton.alpha = 1
        })
    }
    
    @objc private func showMessage() {
        UIView.animate(withDuration: 0.5, animations: {
            self.messageLabel.alpha = 1
        })
        
    }
    
    func random(_ from: Int, to: Int) -> Int {
        let _to = to + 1
        guard _to > from else {
            assertionFailure("Can not generate negative random numbers")
            return 0
        }
        return Int(arc4random_uniform(UInt32(_to - from)) + UInt32(from))
    }
}

