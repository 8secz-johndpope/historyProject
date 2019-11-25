//
//  FeatureCollectionCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 7/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import AVKit

class FeatureVideoCell : UICollectionViewCell {
    
    static let CellIdentifier = "FeatureVideoCellID"
    internal var PlayButtonSize = CGSize(width:56,height:56)
    internal var SoundButtonSize = CGSize(width:30,height:30)
//    fileprivate let PauseButtonSize = CGSize(width:24,height:24)
    internal var playerLayer : VideoPlayerViewController?
    
    internal var playButton = UIButton(type: .custom)
    internal var soundButton = UIButton(type: .custom)
//    fileprivate var pauseButton = UIButton(type: .custom)
    var videoURL: URL? = nil
    internal var featureImageView: UIImageView!
    internal var isUserPausedVideo = false //To check if user pressed on pause video
    fileprivate var isPlaying = false
    internal var defaultMute = false
    internal var shouldShowCoverImageWhenPause = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        self.playerLayer = VideoPlayerViewController()
        self.playerLayer!.showsPlaybackControls = false
        self.playerLayer!.view.frame = self.bounds
        self.contentView.addSubview(self.playerLayer!.view)
        
        featureImageView = UIImageView(frame: bounds)
//        featureImageView.isHidden = true
        self.contentView.addSubview(featureImageView)
        
        playButton.setImage(UIImage(named: "play_bt") , for: .normal)
        playButton.addTarget(self, action: #selector(FeatureVideoCell.buttonPlayPressed), for: .touchUpInside)
        playButton.track_consoleTitle = "播放"
        if let url = self.videoURL?.absoluteString {
            playButton.track_media = url
        }
        self.contentView.addSubview(playButton)
        
        soundButton.setImage(UIImage(named: "volume_on") , for: .normal)
        soundButton.setImage(UIImage(named: "volume_off") , for: .selected)
        soundButton.isHidden = true
        soundButton.addTarget(self, action: #selector(FeatureVideoCell.soundButtonPressed), for: .touchUpInside)
        soundButton.track_consoleTitle = "音量"
        soundButton.isHidden = true
        if let url = self.videoURL?.absoluteString {
            soundButton.track_media = url
        }
        self.contentView.addSubview(soundButton)
        
//        pauseButton.setImage(UIImage(named: "pause_bt") , for: .normal)
//        pauseButton.addTarget(self, action: #selector(FeatureVideoCell.userPausedVideo), for: .touchUpInside)
//        pauseButton.track_consoleTitle = "暂停"
//        pauseButton.isHidden = true
//        if let url = self.videoURL?.absoluteString {
//            pauseButton.track_media = url
//        }
//        self.contentView.addSubview(pauseButton)
    }
    
    open func setImageURL(_ urlString: String, contentMode: UIViewContentMode = .scaleAspectFill) {
        if  !urlString.isEmpty, let url = URL(string: urlString) {
            featureImageView.mm_setImageWithURL(url, placeholderImage: UIImage(named: "holder"), contentMode: contentMode)
        } else {
            featureImageView.image = UIImage(named: "holder")
        }
    }
    
    //MARK: - Network check
    
    private func isUsingWifi() -> Bool {
        let reachability = Reachability.shared()
        let status: NetworkStatus = reachability!.currentReachabilityStatus()
        if status == ReachableViaWiFi {
            return true
        }
        return false
    }
    
    //MARK: - Video Player
    
    func initMoviePlayer(_ urlString: String) {
        if let url = URL(string: urlString) {
            videoURL = url
        }
    }
    
    open func setVideoURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            videoURL = nil
            stopVideo()
            return 
        }
        if videoURL != url {
            if videoURL == nil {
                self.initMoviePlayer(urlString)
            } else {
                stopVideo() // remove player in reuse cell case, will init player item when try to play video
                videoURL = url
                self.featureImageView.isHidden = false
            }
        }
    }
    
    open func startVideo() {
        //must be init before calling
        guard let _ = videoURL else {
            return
        }
        
        self.setPlayerItem()
        
        if isUsingWifi() {
            self.playAtBeginning()
        } else {
            self.featureImageView.isHidden = false
            self.isUserPausedVideo = true
            self.contentView.bringSubview(toFront: playButton)
            setStatusForVideoView(isPlaying: false)
        }
    }
    
    open func setPlayerItem() {
        guard let url = videoURL else {
            return
        }
        
        if self.playerLayer?.player == nil /* setup player if not yet init */ {
            let playerItem = CachePlayerItem(url: url)
            playerItem.delegate = self
            let avPlayer = AVPlayer(playerItem: playerItem)
            if #available(iOS 10.0, *) {
                avPlayer.automaticallyWaitsToMinimizeStalling = false
            }
            self.playerLayer?.player = avPlayer
            self.playerLayer?.player?.isMuted = defaultMute
            self.soundButton.isSelected = defaultMute
            NotificationCenter.default.addObserver(self, selector: #selector(videoReplay), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerLayer?.player?.currentItem)
        }
    }
    
    open func resumeVideo() {
        
        //If video is playing
        if playerLayer?.player?.rate != 0 {
            return
        }
        
        isUserPausedVideo = false
        playerLayer?.player?.play()
        setStatusForVideoView(isPlaying: true)
    }
    
    open func pauseVideo() {
//        if isPlaying, let currentDuration = playerLayer?.player?.currentItem?.currentTime() {
//            let currentSecs = Int(CMTimeGetSeconds(currentDuration).rounded())
//            print("Video \(videoURL?.absoluteString) pause at : \(currentSecs) Sec")
//        }
        
        playerLayer?.player?.pause()
        setStatusForVideoView(isPlaying: false)
    }
    
    @objc func userPausedVideo() {
        isUserPausedVideo = true
        self.pauseVideo()
    }
    
    @objc func videoReplay() {
        //手动埋点
        self.track_consoleTitle = "自动播放"
        MMTrack.tracker().viewAction(page: self.track_page(), comp: self, event: UIEvent())
        self.track_consoleTitle = ""
        
        self.playAtBeginning()
    }
    
    @objc private func playAtBeginning() {
        playerLayer?.player?.seek(to: kCMTimeZero)
        playerLayer?.player?.play()
        
        setStatusForVideoView(isPlaying: true)
    }
    
    internal func setStatusForVideoView(isPlaying: Bool) {
        self.isPlaying = isPlaying
        if isPlaying {
            featureImageView.isHidden = true
        } else if shouldShowCoverImageWhenPause {
            featureImageView.isHidden = false
        }
        playButton.isHidden = isPlaying
        soundButton.isHidden = !isPlaying
//        pauseButton.isHidden = !isPlaying
    }
    
    //basically don't call this function, otherwise have to init again
    open func stopVideo() {
        playerLayer?.player?.pause()
        playerLayer?.player?.replaceCurrentItem(with: nil)
        playerLayer?.player = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Actions
    
    @objc func buttonPlayPressed() {
        isUserPausedVideo = false
        playerLayer?.player?.play()
        setStatusForVideoView(isPlaying: true)
    }
    
    @objc func soundButtonPressed() {
        var isMuted = self.playerLayer?.player?.isMuted ?? false
        isMuted = !isMuted
        
        self.soundButton.isSelected = isMuted
        self.playerLayer?.player?.isMuted = isMuted
        
        
        do {
            try AVAudioSession.sharedInstance().setCategory(isMuted ? AVAudioSessionCategoryAmbient : AVAudioSessionCategoryPlayback)
        } catch {}
    }
    
    /* internal function for Product Banner Video Cell */
    internal func showCoverImage() {
        featureImageView.isHidden = false
        playerLayer?.view.isHidden = true
        playButton.isHidden = true
        soundButton.isHidden = true
//        pauseButton.isHidden = true
    }

    internal func showVideoComponent() {
        playerLayer?.view.isHidden = false
    }
    
    //MARK: - 
   
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var bounds = self.bounds
        if let player = playerLayer?.view {
            bounds = player.bounds
        }
        
        playButton.frame = CGRect(x:(bounds.sizeWidth - PlayButtonSize.width) / 2,y: (bounds.sizeHeight - PlayButtonSize.height) / 2,width: PlayButtonSize.width,height: PlayButtonSize.height)
//        soundButton.frame = CGRect(x: bounds.sizeWidth - SoundButtonSize.width - 10, y: 10, width: SoundButtonSize.width, height: SoundButtonSize.height)
        soundButton.frame = CGRect(x: 10, y: bounds.sizeHeight - SoundButtonSize.height - 10, width: SoundButtonSize.width, height: SoundButtonSize.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        playerLayer?.view.removeFromSuperview()
        playerLayer = nil
        self.stopVideo()
    }
    
    /* for PDP usage, don't touch */
    open func playVideo(_ urlString: String) {
        
        var firstInitializedVideo = false
        if videoURL == nil {
            self.initMoviePlayer(urlString)
            firstInitializedVideo = true
        }
        
        if self.playerLayer?.player == nil /* setup player if not yet init */ {
            let playerItem = CachePlayerItem(url: videoURL!)
            playerItem.delegate = self
            let avPlayer = AVPlayer(playerItem: playerItem)
            if #available(iOS 10.0, *) {
                avPlayer.automaticallyWaitsToMinimizeStalling = false
            }
            self.playerLayer?.player = avPlayer
            self.playerLayer?.player?.isMuted = defaultMute
            self.soundButton.isSelected = defaultMute
            NotificationCenter.default.addObserver(self, selector: #selector(videoReplay), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerLayer?.player?.currentItem)
        }
        
        if firstInitializedVideo {
            if isUsingWifi() {
                self.playAtBeginning()
            } else {
                self.featureImageView.isHidden = false
                self.isUserPausedVideo = true
                self.contentView.bringSubview(toFront: playButton)
                setStatusForVideoView(isPlaying: false)
            }
        } else if !self.isUserPausedVideo {
            self.resumeVideo()
        }
    }
    
}

extension FeatureVideoCell: CachePlayerItemDelegate {
    
    func playerItem(_ playerItem: CachePlayerItem, didFinishDownloadingData data: Data) {
        print("File is downloaded and ready for storing")
    }
    
    func playerItem(_ playerItem: CachePlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
//        print("\(bytesDownloaded)/\(bytesExpected)")
    }
    
    func playerItemPlaybackStalled(_ playerItem: CachePlayerItem) {
        print("Not enough data for playback. Probably because of the poor network. Wait a bit and try to play later.")
    }
    
    func playerItem(_ playerItem: CachePlayerItem, downloadingFailedWith error: Error) {
        print(error)
    }
    
}
