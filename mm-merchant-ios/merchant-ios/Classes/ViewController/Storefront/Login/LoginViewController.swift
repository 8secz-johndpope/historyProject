//
//  LoginVC.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 28/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import JPSVolumeButtonHandler

class LoginViewController : SignupModeViewController, WeChatAuthDelegate {
    var loginButtonView = LoginButtonView()
    var signupButtonView = SignupButtonView()
    let loginButtonsPadding: CGFloat = 14.0
    var longPressRecognizer : UILongPressGestureRecognizer?
    
    var crossView : UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImageView = UIImageView(frame: self.view.frame)
        backgroundImageView.image = UIImage(named: "login_bg")
        self.view.addSubview(backgroundImageView)
        
        let loginButtonViewHeight = loginButtonView.upperButton.frame.height + loginButtonView.lowerButton.frame.height + loginButtonsPadding
        loginButtonView.frame = CGRect(x: self.view.frame.minX, y: self.view.frame.maxY - (loginButtonViewHeight + 30), width: self.view.frame.width, height: loginButtonViewHeight)
        self.view.addSubview(loginButtonView)
        
        
        signupButtonView.frame = CGRect(x: self.view.frame.minX, y: loginButtonView.frame.minY - (80 + 25), width: self.view.frame.width, height: 80)
        
        self.view.addSubview(signupButtonView)

		loginButtonView.upperButton.addTarget(self, action: #selector(SignupModeViewController.mobileLogin), for: .touchUpInside)
		loginButtonView.lowerButton.addTarget(self, action: #selector(LoginViewController.guestLogin), for: .touchUpInside)
		signupButtonView.leftLabel.text = String.localize("LB_CA_WECHAT_LOGIN")
		signupButtonView.rightLabel.text = String.localize("LB_CA_MOBILE_REGISTRATION")
		signupButtonView.leftButton.addTarget(self, action:#selector(SignupModeViewController.wechatButtonClicked), for: .touchUpInside )
		longPressRecognizer = UILongPressGestureRecognizer(target: self, action:#selector(LoginViewController.leftButtonLongPressed))
		signupButtonView.leftButton.addGestureRecognizer(longPressRecognizer!)
		signupButtonView.rightButton.addTarget(self, action:#selector(SignupModeViewController.mobileSignup), for: .touchUpInside )

		crossView = { () -> UIView in
            
            let buttonWidth = CGFloat(30)
            let buttonHeight = CGFloat(30)
            let buttonPadding = CGFloat(5)
            let viewTopPadding = CGFloat(20)
            let viewRightPadding = CGFloat(5)
            let viewWidth = buttonWidth + 2*buttonPadding
            let viewWHeight = buttonHeight + 2*buttonPadding
            let view = UIView (frame: CGRect(x: self.view.frame.size.width - viewWidth - viewRightPadding, y: viewTopPadding, width: viewWidth, height: viewWHeight))
            let button = UIButton(type: .custom)
            button.setImage(UIImage(named: "icon_cross"), for: UIControlState())
            button.frame = CGRect(x: buttonPadding, y: buttonPadding, width: buttonWidth, height: buttonHeight)
            button.addTarget(self, action: #selector(LoginViewController.closeButtonTapped), for: .touchUpInside)
            view.addSubview(button)
            
            return view
        } ()
        self.view.addSubview(crossView)
        
        adjustUIBySignupMode()
        
        let exclusiveButton = UIButton(frame: CGRect(x: (self.view.frame.size.width - 100) / 2, y: 170, width: 100, height: 60))
        exclusiveButton.addTarget(self, action: #selector(self.gotoExclusive), for: UIControlEvents.touchUpInside)
        self.view.addSubview(exclusiveButton)
    }
    
    func handleWeChatCallback(_ authResponseCode: String){
        self.loginWeChatWithCode(authResponseCode)
    }
    
    @objc func gotoExclusive(){
        let mobileSignupViewController = InvitationCodeSuccessfulViewController()
        self.navigationController?.push(mobileSignupViewController, animated: true)
    }
    
    func adjustUIBySignupMode () {
        if self.signupMode == .normal {
            loginButtonView.lowerButton.isHidden = false
            crossView.isHidden = true
            
        } else {
            loginButtonView.lowerButton.isHidden = true
            crossView.isHidden = false
        }
    }
    
    @objc func closeButtonTapped () {
        self.dismiss(animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController!.isNavigationBarHidden = true
//        NotificationCenter.default.addObserver(self, selector: #selector(loginWeChat(_:)), name: "LoginWeChat", object: nil)
        WeChatManager.sharedInstance().delegate = self
        //self.handleDeeplink()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController!.isNavigationBarHidden = false
        NotificationCenter.default.removeObserver(self)
        
    }
    
    override func setupVolumeButtonHandler() {
        self.volumeButtonHandler = JPSVolumeButtonHandler(up: {
            self.navigationController?.push(InterestCategoryPickViewController(), animated: true)
        }, downBlock: {
            
        })
    }
    
//    func handleDeeplink() {
//        if DeepLinkManager.sharedManager.pendingDeeplink != nil { //Handle deeplink
//            LoginManager.goToStorefront()
//        }
//    }
    func addTextField(){
        
    }
    
    //MARK: Guest Login
    @objc func guestLogin(_ button: UIButton) {
        Utils.requestLocationAndPushNotification()
        
        LoginManager.guestLogin()
        LoginManager.goToStorefront()
    }
    
    //MARK: AliPay, Don't remove
    @objc func leftButtonLongPressed(_ button : UIButton){
        signupButtonView.leftButton.removeGestureRecognizer(longPressRecognizer!)
    }
    

}
