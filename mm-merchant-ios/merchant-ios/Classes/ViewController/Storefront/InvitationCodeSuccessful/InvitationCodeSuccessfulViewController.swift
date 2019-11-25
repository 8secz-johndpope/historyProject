//
//  InvitationCodeSuccessfulViewController.swift
//  merchant-ios
//
//  Created by LongTa on 7/28/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import MediaPlayer
import AVKit

class InvitationCodeSuccessfulViewController: SignupModeViewController {
    private var moviePlayer: AVPlayerViewController?
    
    private lazy var dismissImageView:UIImageView = {
        let dismissImageView = UIImageView()
        dismissImageView.image = UIImage.init(named: "signup_close")
        dismissImageView.sizeToFit()
        dismissImageView.isUserInteractionEnabled = true
        dismissImageView.isHidden = true
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(self.guestModeLogin))
        dismissImageView.addGestureRecognizer(tapGesture)
        return dismissImageView
    }()
    
//    var crossView : UIView!
    var hideCrossView = false
    var sessionCategory: String?
    
    //MARK: - Lazy
   private lazy var loginView:RootLoginView = {
        let loginView = RootLoginView.initWithFrame(self.view.bounds)
        loginView?.wechatButton.addTarget(self, action:#selector(self.wechatButtonClicked), for: .touchUpInside)
//        loginView?.loginButton.addTarget(self, action:#selector(self.didClickMobileLogin), for: .touchUpInside )
        loginView?.loginButton.addTarget(self, action:#selector(self.mobileSignup), for: .touchUpInside )
        loginView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss as (() -> Void))))
        loginView?.visitButton.addTarget(self, action: #selector(self.guestModeLogin), for: UIControlEvents.touchUpInside)
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(self.didClickMobileLogin))
        loginView?.loginImageView.addGestureRecognizer(tapGesture)
        return loginView!
    }()
    
    private var enableAccountLogin = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let hide = ssn_Arguments["hideCross"]?.bool {
            self.hideCrossView = hide
        }
        
        if self.moviePlayer == nil {
            self.moviePlayer = AVPlayerViewController()
            moviePlayer?.view.frame = self.view.bounds
            moviePlayer?.showsPlaybackControls = false
            moviePlayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill.rawValue
            
            NotificationCenter.default.addObserver(self, selector: #selector(InvitationCodeSuccessfulViewController.playerItemDidReachEnd), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: moviePlayer?.player?.currentItem)
            
            if moviePlayer?.player?.currentItem == nil, let path = Bundle.main.path(forResource: "loginVideo", ofType: "MP4") {
                moviePlayer?.player = AVPlayer(url: URL(fileURLWithPath: path, isDirectory: false))
            }
            moviePlayer?.player?.isMuted = true
//            moviePlayer.player?.play()
        }
        
        view.addSubview(loginView)
        view.insertSubview(moviePlayer!.view, at: 0)
        view.addSubview(dismissImageView)
        dismissImageView.snp.makeConstraints { (make) in
            make.top.equalTo(ScreenTop + 35 )
            make.left.equalTo(20)
        }
        
        if hideCrossView {
            dismissImageView.isHidden = true
        } else{
            dismissImageView.isHidden = false
        }

        initAnalyticsViewRecord(
            viewLocation: "SignupOptions",
            viewType: "Exclusive"
        )
        
        LoginManager.shouldEnableAccountLogin { (enable) in
            self.enableAccountLogin = enable
        }
    }
    
    //MARK: - Life cycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        WeChatManager.sharedInstance().delegate = self
        playerItemDidReachEnd()
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.statusBarStyle = .default
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func resumeVideo() {
        moviePlayer?.player?.play()
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    @objc func playerItemDidReachEnd() {
        moviePlayer?.player?.seek(to: kCMTimeZero)
        moviePlayer?.player?.play()
    }
    
    @objc func didClickMobileLogin(button: UIButton) {
        self.dismiss()
        self.mobileLogin(button)
        button.analyticsViewKey = self.analyticsViewRecord.viewKey
        button.recordAction(.Tap, sourceRef: "Login", sourceType: .Button, targetRef: "Login", targetType: .Table)
        
    }
    
    @objc override func mobileSignup(_ button : UIButton) {
        if self.enableAccountLogin {
            self.dismiss()
            self.mobileLogin(button)
        } else {
            super.mobileSignup(button)
            button.analyticsViewKey = self.analyticsViewRecord.viewKey
            button.recordAction(.Tap, sourceRef: "Signup", sourceType: .Button, targetRef: "Signup", targetType: .Table)
        }
    }
    
    @objc override func wechatButtonClicked(_ button: UIButton){
        super.wechatButtonClicked(button)
        self.recordWeChatAction(isLogin: true)
    }
    
    @objc func dismiss() {
        self.view.endEditing(true)
    }
    
    @objc func guestModeLogin(button : UIButton) {
        button.analyticsViewKey = self.analyticsViewRecord.viewKey
        button.recordAction(.Tap, sourceRef: "GuestMode", sourceType: .Link, targetRef: "GuestMode", targetType: .Table)
        if LoginManager.hasStorefront() {
            self.ssn_back()
        }
    }

    override func recordWeChatAction(isLogin: Bool) {
        loginView.wechatButton.analyticsViewKey = self.analyticsViewRecord.viewKey
        if isLogin {
            loginView.wechatButton.recordAction(.Tap, sourceRef: "WechatLogin", sourceType: .Button, targetRef: "WechatLogin", targetType: .Table)
        }else {
            loginView.wechatButton.recordAction(.Tap, sourceRef: "WeChatSignup", sourceType: .Button, targetRef: "WeChatAuthentication", targetType: .View)
        }
    }
}

//MARK: - Delegate
extension InvitationCodeSuccessfulViewController:WeChatAuthDelegate{
    func handleWeChatCallback(_ authResponseCode: String){
        self.loginWeChatWithCode(authResponseCode)
    }
}

extension InvitationCodeSuccessfulViewController: MMNavigationControllerDelegate {
    func preferredNavigationBarVisibility() -> MmFadeNavigationControllerNavigationBarVisibility? {
        return .hidden
    }
}

