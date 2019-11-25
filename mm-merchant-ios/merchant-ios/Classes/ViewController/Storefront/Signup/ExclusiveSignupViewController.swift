//
//  ExclusiveSignupViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
class ExclusiveSignupViewController: MobileSignupViewController, WeChatAuthDelegate, SwipeSMSDelegate {
    let wechatView = UIView()
    final let WechatIconWith : CGFloat = 80
    final let WechatTextHeight : CGFloat = 40
    final let WechatIconMarginTop : CGFloat = 20
    final let WechatMarginBottom : CGFloat = 30
    var swipeSMSView: SwipeSMSView!
    override func viewDidLoad() {
        super.viewDidLoad()
        switch viewMode {
        case .signUp, .wechat:
            self.title = String.localize("LB_CA_REGISTER")
        case .profile:
            self.title = String.localize("LB_CA_MY_ACCT_MODIFY_MOBILE")
        }
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.loginWeChat(_:)), name: "LoginWeChat", object: nil)
        WeChatManager.sharedInstance().delegate = self
        
    }
    
    func handleWeChatCallback(_ authResponseCode: String){
        self.loginWeChatWithCode(authResponseCode)
    }
    
    override func createSubviews() {
        
        signupInputView = SignupInputView(frame: CGRect(x: InputViewMarginLeft, y: 84, width: self.view.bounds.width - InputViewMarginLeft * 2, height: 95))
        scrollView.addSubview(signupInputView)
        signupInputView.hideCountryButton(true)
        signupInputView.countryTextField.delegate = self
        signupInputView.countryTextField.inputView = self.countryPicker
        swipeSMSView = SwipeSMSView(frame: CGRect(x: InputViewMarginLeft, y: signupInputView.frame.maxY + 23, width: self.view.bounds.width - InputViewMarginLeft * 2, height: 45))
        swipeSMSView?.timeCountdown = 60
        swipeSMSView?.swipeSMSDelegate = self
        swipeSMSView?.isEnableSwipe = false
        scrollView.addSubview(swipeSMSView!)
        let verificationPostY = swipeSMSView?.frame.maxY ?? 0
        verificationCodeView = VerificationCodeView(frame: CGRect(x: InputViewMarginLeft, y: verificationPostY + 10, width: self.view.bounds.width - InputViewMarginLeft * 2, height: 46 + 42 + 70))
        verificationCodeView?.viewMode = self.viewMode
        verificationCodeView?.signupMode = self.signupMode
        scrollView.addSubview(verificationCodeView!)
        verificationCodeView?.isHidden = true
        verificationCodeView?.button.addTarget(self, action: #selector(MobileSignupViewController.checkMobileVerification), for: .touchUpInside)
        
        verificationCodeView?.buttonCheckbox.addTarget(self, action: #selector(self.didClickCheckBoxButton), for: UIControlEvents.touchUpInside)
        verificationCodeView?.buttonLink.addTarget(self, action: #selector(self.didClickLinkButton), for: UIControlEvents.touchUpInside)
        verificationCodeView?.buttonPrivacy.addTarget(self, action: #selector(self.didClickLinkButton), for: UIControlEvents.touchUpInside)
        verificationCodeView?.button.formatTransparent()
        verificationCodeView?.isShowTNC = true
        //verificationCodeView?.textfield.isEnabled = false
        signupInputView.activeCodeTextField.tag = SignupTextFieldTag.verificationCode.rawValue
        signupInputView.activeCodeTextField.delegate = self
        signupInputView.codeTextField.text = Constants.CountryMobileCode.DEFAULT
        signupInputView.mobileNumberTextField.becomeFirstResponder()
        signupInputView.codeTextField.delegate = self
        signupInputView.mobileNumberTextField.keyboardType = .numberPad
        signupInputView.mobileNumberTextField.delegate = self
        

        let wechatViewHeight = WechatIconWith + WechatTextHeight + WechatMarginBottom + WechatIconMarginTop
        wechatView.frame = CGRect(x: 0, y: verificationPostY + WechatIconMarginTop, width: self.view.frame.width, height: wechatViewHeight)
        let lineView = UIView(frame:  CGRect(x: InputViewMarginLeft, y: 0, width: self.view.bounds.width - InputViewMarginLeft * 2, height: 1))
        lineView.backgroundColor = UIColor.secondary1()
        let wechatButton = UIButton(frame:  CGRect(x: self.view.bounds.midX - WechatIconWith / 2, y: WechatIconMarginTop, width: WechatIconWith, height: WechatIconWith))
        wechatButton.setImage(UIImage(named: "wechat"), for: UIControlState())
        wechatButton.addTarget(self, action:#selector(self.wechatButtonClicked), for: .touchUpInside )
        let wechatLabel = UILabel(frame:  CGRect(x: 0, y: wechatButton.frame.maxY, width: self.view.bounds.width, height: 30))
        wechatLabel.formatSize(14)
        wechatLabel.text = String.localize("LB_CA_WECHAT_LOGIN")
        wechatLabel.textAlignment = .center
        wechatLabel.textColor = UIColor.secondary3()
        wechatView.addSubview(wechatButton)
        wechatView.addSubview(wechatLabel)
        wechatView.addSubview(lineView)
        scrollView.addSubview(wechatView)
        scrollView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        scrollView.contentSize = CGSize(width: self.view.bounds.width, height: wechatLabel.frame.maxY)
        self.view.addSubview(scrollView)
    }
    
    
    
        
    override func checkMobileVerification(_ button: UIButton){
        if !self.isEnoughInfo() {
            return
        }
        self.dismissKeyboard()
        super.checkMobileVerification(button)
    }
    
    
    func showVerificationView() {
        var frame = self.wechatView.frame
        if let view = self.verificationCodeView  {
            if view.isHidden {
                frame.origin.y = swipeSMSView?.frame.maxY ?? 0
            } else {
                frame.origin.y = self.view.frame.height - frame.height
            }
        }
        wechatView.frame = frame
    }
    
}
