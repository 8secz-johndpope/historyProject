//
//  ProductListVideoView.swift
//  storefront-ios
//
//  Created by Kam on 23/7/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class ProductListVideoView: UIView {
    
    open var closeButtonClickHandler: (() -> Void)?
    open var fullScreenClickHandler: (() -> Void)?
    open var videoPlayAction: (() -> Void)? {
        didSet {
            let action = self.videoPlayAction
            let handler: (() -> Void) = {
                action?()
                self.isPlaying = true
            }
            self.videoPlayAction = handler
        }
    }
    open var videoStopAction: (() -> Void)? {
        didSet {
            let action = self.videoStopAction
            let handler: (() -> Void) = {
                action?()
                self.isPlaying = false
            }
            self.videoStopAction = handler
        }
    }
    
    public var isPlaying = false
    
    var playButton: UIButton? {
        didSet {
            self.playButton?.addTarget(self, action: #selector(ProductListVideoView.playVideo), for: .touchUpInside)
        }
    }
    var soundButton, fullScreenButton: UIButton?
    var featuredImage: UIImageView? {
        didSet {
            self.featuredImage?.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin,
                                     UIViewAutoresizing.flexibleRightMargin,
                                     UIViewAutoresizing.flexibleLeftMargin,
                                     UIViewAutoresizing.flexibleTopMargin,
                                     UIViewAutoresizing.flexibleWidth,
                                     UIViewAutoresizing.flexibleHeight]
        }
    }
    
    private var isAppeared: Bool = false
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit header video view")
        self.videoStopAction?()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        guard !isAppeared else { return }
        
        isAppeared = true
        
        if self.shouldAutoPlay() {
            self.playVideo()
        } else {
            self.videoStopAction?()
        }
    }
    
    @objc private func playVideo() {
        if let videoPlay = videoPlayAction {
            videoPlay()
        }
    }
    
    private func shouldAutoPlay() -> Bool {
        let reachability = Reachability.shared()
        let status: NetworkStatus = reachability!.currentReachabilityStatus()
        if status == ReachableViaWiFi {
            return true
        }
        else if status == ReachableViaWWAN {
            return CTTelephonyNetworkInfo().currentRadioAccessTechnology == CTRadioAccessTechnologyLTE
        }
        return false
    }
    
    open func toFloatingView() {
        soundButton?.isHidden = true
        fullScreenButton?.isHidden = true
        
//        self.round(4)
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.masksToBounds = false
        self.layer.shadowOpacity = 0.5
        self.layer.shadowOffset = CGSize(width: 2, height: 2)
        self.layer.shadowRadius = 2
    }
    
    open func toTopView() {
        soundButton?.isHidden = false
        fullScreenButton?.isHidden = false
        
        self.round(0)
        self.layer.shadowOpacity = 0
    }
}
