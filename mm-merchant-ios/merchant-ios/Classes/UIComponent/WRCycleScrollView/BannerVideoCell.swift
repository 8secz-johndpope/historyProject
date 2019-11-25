//
//  BannerVideoCell.swift
//  storefront-ios
//
//  Created by Kam on 16/4/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit

class BannerVideoCell: FeatureVideoCell {
    
    enum BannerType: String {
        case undefine,
        topBanner,
        productBanner
    }
    
    internal var FullScreenButtonSize = CGSize(width:30,height:30)
    internal var moreImageView: UIImageView!
    internal var overlayVideoView = UIView()
    internal var fullScreenButton = UIButton(type: .custom)
    var focusing: Bool = false
    open var bannerType: BannerType = .undefine
    public var padding:CGFloat = 0.0
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.defaultMute = true
        
        overlayVideoView.frame = self.bounds
        overlayVideoView.backgroundColor = UIColor.clear
        overlayVideoView.isUserInteractionEnabled = true
        overlayVideoView.track_consoleTitle = "查看详情"
        if let url = self.videoURL?.absoluteString {
            overlayVideoView.track_media = url
        } else {
            overlayVideoView.track_media = ""
        }
        if let view = self.playerLayer?.view {
            self.contentView.insertSubview(overlayVideoView, aboveSubview: view)
        }
        
        moreImageView = UIImageView()
        moreImageView.image = UIImage(named: "more_bt")
        moreImageView.sizeToFit()
        moreImageView.frame = CGRect(x: frame.size.width - moreImageView.frame.size.width - 15, y: frame.size.height - moreImageView.frame.size.height - 10, width: moreImageView.frame.size.width, height: moreImageView.frame.size.height)
        moreImageView.isUserInteractionEnabled = true
        moreImageView.isHidden = true
        moreImageView.track_consoleTitle = "查看更多"
        self.contentView.addSubview(moreImageView)
        
        fullScreenButton.setImage(UIImage(named: "fullscreen_on") , for: .normal)
        fullScreenButton.isHidden = true
        fullScreenButton.addTarget(self, action: #selector(BannerVideoCell.fullScreenPressed), for: .touchUpInside)
        fullScreenButton.frame = CGRect(x: frame.size.width - FullScreenButtonSize.width - 15, y: frame.size.height - FullScreenButtonSize.height - 10, width: FullScreenButtonSize.width, height: FullScreenButtonSize.height)
        self.contentView.addSubview(fullScreenButton)
        
        self.playerLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill.rawValue
        
        if #available(iOS 11.0, *) {
            self.playerLayer?.contentOverlayView?.addObserver(self, forKeyPath: "frame", options: .new, context: nil)
        } else {
            self.playerLayer?.contentOverlayView?.addObserver(self, forKeyPath: "bounds", options: .new, context: nil)
        }
    }
    
    deinit {
        if #available(iOS 11.0, *) {
            self.playerLayer?.contentOverlayView?.removeObserver(self, forKeyPath: "frame")
        } else {
            self.playerLayer?.contentOverlayView?.removeObserver(self, forKeyPath: "bounds")
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "frame" || keyPath == "bounds" {
            if let change = change, let newRect = change[.newKey] as? NSValue {
                let newFrame: CGRect = newRect.cgRectValue as CGRect
                
                guard let playerVC = self.playerLayer, let player = playerVC.player else {
                    return
                }
                
                let playerBounds = playerVC.view.bounds
                let playerWidth = playerBounds.width
                let playerHeight = playerBounds.height
                
                let fullScreen = !(floor(playerWidth) == floor(newFrame.size.width) && floor(playerHeight) == floor(newFrame.size.height))
                
                playerVC.showsPlaybackControls = fullScreen
                VideoPlayManager.shared.isFullScreen = fullScreen
                let shouldKeepPlaying = /*(player.rate != 0.0)*/ true

                if shouldKeepPlaying {
                    DispatchQueue.main.asyncAfter(deadline: .now() + VideoPlayManager.delayInterval) {
                        if player.rate == 0.0 && !fullScreen {
                            if !self.isUserPausedVideo { self.resumeVideo() }
                            player.isMuted = self.soundButton.isSelected
                        }
                    }
                }
                
                if !fullScreen {
                    DispatchQueue.main.asyncAfter(deadline: .now() + VideoPlayManager.delayInterval) {
                        playerVC.videoGravity = AVLayerVideoGravity.resizeAspectFill.rawValue
                    }
                }
                UIApplication.shared.setStatusBarHidden(false, with: .none)
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    override func pauseVideo() {
        super.pauseVideo()
        self.focusing = false
    }
    
    override func buttonPlayPressed() {
        VideoPlayManager.shared.videoPlayInterrupt(trigger: self) //interrupt other active player
        self.focusing = true
        super.buttonPlayPressed()
    }
    
    @objc private func fullScreenPressed() {
        VideoPlayManager.shared.videoStartFullScreen(self.playerLayer, delegate: self)
    }
    
    open func setDeeplink(_ link: String) {
        moreImageView.isHidden = link.isEmpty
        overlayVideoView.isHidden = link.isEmpty
        if !link.isEmpty {
            moreImageView.whenTapped {
                self.deeplinkHandler(link)
            }
            overlayVideoView.whenTapped {
                self.deeplinkHandler(link)
            }
        }
    }
    
    private func deeplinkHandler(_ link: String) {
        var videoView: ProductListVideoView?
        if self.bannerType == .topBanner || self.bannerType == .productBanner {
            weak var videoCell: BannerVideoCell?
            videoCell = self.duplicateVideoCell()
            if let strongCell = videoCell {
                let view = strongCell.contentView
                view.autoresizingMask = [UIViewAutoresizing.flexibleBottomMargin,
                                         UIViewAutoresizing.flexibleRightMargin,
                                         UIViewAutoresizing.flexibleLeftMargin,
                                         UIViewAutoresizing.flexibleTopMargin,
                                         UIViewAutoresizing.flexibleWidth,
                                         UIViewAutoresizing.flexibleHeight]
                
                videoView = ProductListVideoView(frame: view.bounds)
                videoView?.playButton = strongCell.playButton
                videoView?.soundButton = strongCell.soundButton
                videoView?.fullScreenButton = strongCell.fullScreenButton
                videoView?.featuredImage = strongCell.featureImageView
                
                videoView?.videoPlayAction = {
                    strongCell.setPlayerItem()
                    strongCell.playerLayer?.player?.seek(to: kCMTimeZero)
                    strongCell.playerLayer?.player?.play()
                    strongCell.setStatusForVideoView(isPlaying: true)
                }
                
                videoView?.videoStopAction = {
                    strongCell.playerLayer?.player?.pause()
                    strongCell.setStatusForVideoView(isPlaying: false)
                }

                videoView?.fullScreenClickHandler = {
                    VideoPlayManager.shared.videoStartFullScreen(strongCell.playerLayer, delegate: strongCell)
                }

                videoView?.closeButtonClickHandler = {
                    videoView?.videoStopAction?()
                    strongCell.isUserPausedVideo = true
                }
                
                strongCell.overlayVideoView.whenTapped {
                    videoView?.fullScreenClickHandler?()
                }
                
                videoView?.addSubview(view)
            }
            
        }
        Navigator.shared.sopen(link, headView: videoView)
    }
    
    private func duplicateVideoCell() -> BannerVideoCell? {
        var bounds: CGRect?
        if let playerBounds = self.playerLayer?.view.bounds {
            let playerWidth = playerBounds.width
            let playerHeight = playerBounds.height
            let ratio = playerWidth / ScreenWidth
            bounds = CGRect(x: 0, y: 0, width: playerWidth/ratio, height: playerHeight/ratio)
        }
        
        let videoCell = BannerVideoCell(frame: bounds ?? self.contentView.bounds)
        videoCell.moreImageView.removeFromSuperview()
        
        if let video = self.videoURL?.absoluteString {
            videoCell.setVideoURL(video)
            videoCell.featureImageView.image = self.featureImageView.image
            videoCell.layoutSubviews()
        }
        
        return videoCell
    }
    
    override func showCoverImage() {
        super.showCoverImage()
        moreImageView.isHidden = true
        fullScreenButton.isHidden = true
        layoutSubviews()
    }
    
    override func setStatusForVideoView(isPlaying: Bool) {
        self.fullScreenButton.isHidden = !isPlaying
        self.moreImageView.isHidden = isPlaying
        super.setStatusForVideoView(isPlaying: isPlaying)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var bounds = self.bounds
        if let player = self.playerLayer?.view {
            bounds = player.bounds
        }
        
        overlayVideoView.frame = bounds
        
        fullScreenButton.frame = CGRect.init(x: bounds.size.width  + padding - FullScreenButtonSize.width - 10, y: bounds.size.height - FullScreenButtonSize.height - 10, width: FullScreenButtonSize.width, height: FullScreenButtonSize.height)
        moreImageView.frame = CGRect(x: bounds.size.width + padding - moreImageView.frame.size.width - 15,
                                     y: bounds.size.height - moreImageView.frame.size.height - 10,
                                     width: moreImageView.frame.size.width,
                                     height: moreImageView.frame.size.height)
        
        playButton.frame = CGRect(x:(bounds.sizeWidth - PlayButtonSize.width) / 2 + padding,y: (bounds.sizeHeight - PlayButtonSize.height) / 2,width: PlayButtonSize.width,height: PlayButtonSize.height)

        soundButton.frame = CGRect(x: 10 + padding, y: bounds.sizeHeight - SoundButtonSize.height - 10, width: SoundButtonSize.width, height: SoundButtonSize.height)
    }
}

extension BannerVideoCell: PlayVideoDelegate {
    
    func setVideoPlayerIsFocus() {
        focusing = true
    }
    
    func setVideoPlayerIsUnfocus() {
        focusing = false
        self.pauseVideo()
    }
    
    func isFocusing() -> Bool {
        return focusing
    }
    
    func isPlayerOutOfScreen(ratio: CGFloat) -> Bool {
        //在window上
        guard let win = self.window else { return true }
        // can get video cell bounds
        guard let videoBounds = self.playerLayer?.view.bounds else { return true }
        
        var bounds = win.bounds
        bounds.origin.y = StartYPos + 45 /* SEGMENT_HEIGHT */
        bounds.size.height = bounds.size.height - bounds.origin.y
        let rect = self.convert(videoBounds, to: win)
        let inter = bounds.intersection(rect)
        //显示区域超过ratio%，
        if inter.size.width * inter.size.height < rect.size.width * rect.size.height * ratio {
            return true
        }
        return false
    }
    
    func videoPlayerAutoStart() -> Bool {
        if !isUserPausedVideo {
            self.startVideo() //auto start
            
            //手动埋点
            self.track_consoleTitle = "自动播放"
            MMTrack.tracker().viewAction(page: self.track_page(), comp: self, event: UIEvent())
            self.track_consoleTitle = ""
            return true
        }
        return false
    }
    
    func videoPlayerFinished() {
        
    }
    
    func videoPlayerFailed() {
        
    }
    
    func videoPlayerInterruption() {
        self.pauseVideo()
    }
    
    
}
