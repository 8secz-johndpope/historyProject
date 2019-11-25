//
//  SignupSecondStepViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/5/2.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit

class SignupSecondStepViewController: MMUIController,PinCodeTextFieldDelegate {
    var mobileCode:String = ""
    var mobileNumber:String = ""
    var mobileVerificationId:String = ""
    var mobileVerificationToken:String = ""
    var viewMode:SignUpViewMode = .signUp
    var signupMode = SignupMode.normal
    
    //MARK: - Lazy
    lazy var bgScrollView:UIScrollView = {
        let bgScrollView = UIScrollView()
        bgScrollView.backgroundColor = .clear
        return bgScrollView
    }()
    lazy var backButtonBackgroundView:UIView = {
        let backButtonBackgroundView = UIView()
        backButtonBackgroundView.backgroundColor = .clear
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(touchBackButton))
        backButtonBackgroundView.addGestureRecognizer(tapGesture)
        return backButtonBackgroundView
    }()
    lazy var backButton:UIButton = {
        let backButton = UIButton()
        backButton.setImage(UIImage.init(named: "back_arrow"), for: UIControlState.normal)
        backButton.sizeToFit()
        backButton.isUserInteractionEnabled = false
        return backButton
    }()
    lazy var titleLabel:UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 24)
        titleLabel.text = String.localize("MSG_ERR_CA_VERCODE_NIL")
        return titleLabel
    }()
    lazy var topTipLabel:UILabel = {
        let topTipLabel = UILabel()
        topTipLabel.font = UIFont.systemFont(ofSize: 12)
//        let str = String.localize("MSG_ACTIVATION_CODE_SENT_TO_MOBILE")
        let message = "(\(mobileCode))\(mobileNumber)"
        topTipLabel.text = message//str.replacingOccurrences(of: "{MobileNumber}", with: meeage)
        topTipLabel.textColor = UIColor.secondary17()
        return topTipLabel
    }()
    
    lazy var editButton: UIButton = {
        let edit = UIButton()
        edit.setImage(UIImage(named: "sms_edit"), for: .normal)
        edit.whenTapped {
            self.ssn_back()
        }
        return edit
    }()
    
    lazy var nextButton:UIButton = {
        let nextButton = UIButton()
        nextButton.setTitleColor(UIColor.white, for: UIControlState.normal)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        nextButton.backgroundColor = UIColor.lightGray
        nextButton.layer.cornerRadius = 4.0
        nextButton.layer.masksToBounds = true
        nextButton.backgroundColor = UIColor(hexString: "#CCCCCC")
        nextButton.setTitle(String.localize("LB_DONE"), for: UIControlState.normal)
        nextButton.addTarget(self, action: #selector(touchNextButton), for: .touchUpInside)
        return nextButton
    }()
    lazy var restartButton:UIButton = {
        let restartButton = UIButton()
        restartButton.setTitleColor(UIColor.gray, for: UIControlState.normal)
        restartButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        restartButton.backgroundColor = UIColor.primary2()
        restartButton.layer.cornerRadius = 4.0
        restartButton.layer.masksToBounds = true
        restartButton.setCountdown(60)
        restartButton.addTarget(self, action: #selector(touchRestartButton), for: .touchUpInside)
        return restartButton
    }()
    lazy var textField:PinCodeTextField = {
        let textField = PinCodeTextField()
        textField.backgroundColor = UIColor.white
        textField.needToUpdateUnderlines = false
        textField.textColor = UIColor.black
        textField.underlineWidth = 40
        textField.underlineHSpacing = 15
        textField.underlineVMargin = 11
        textField.characterLimit = 6
        textField.underlineHeight = 2
        textField.font = UIFont.systemFont(ofSize: 47)
        textField.delegate = self
        textField.becomeFirstResponder()
        return textField
    }()
    lazy var erroView:SignupErroView = {
        let erroView = SignupErroView()
        erroView.isHidden = true
        return erroView
    }()
    
    //MARK: - Life cycle
    public override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        self.view.backgroundColor = .white
        
        self.view.addSubview(bgScrollView)
        bgScrollView.addSubview(titleLabel)
        bgScrollView.addSubview(topTipLabel)
        bgScrollView.addSubview(editButton)
        bgScrollView.addSubview(nextButton)
        bgScrollView.addSubview(textField)
        bgScrollView.addSubview(restartButton)
        bgScrollView.addSubview(backButtonBackgroundView)
        bgScrollView.addSubview(backButton)
        bgScrollView.addSubview(erroView)
        
        return true
    }
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        createAutoLayout()
    }
    
    deinit {
        restartButton.cancelCountdown()
    }
    
    //MARK: - Touch events
    @objc func touchRestartButton()  {
        restartButton.setCountdown(60)
        SignupService.getsms(mobileCode: mobileCode, mobileNumber: mobileNumber, success: { (model) in
            self.mobileVerificationId = String(model.mobileVerificationId)
        }) { (erro) -> Bool in
            return true
        }
    }
    
    @objc func touchBackButton()  {
        Alert.alert(self, title: "", message: String.localize("LB_CA_SIGNUP_CANCEL"), okActionComplete: { () -> Void in
            self.navigationController?.popViewController(animated: true)
        }, cancelActionComplete:nil)
    }
    
    @objc func touchNextButton()  {
        let regexText = "^[0-9]+$"
        if RegexManager.matchesForRegexInText(regexText, text: mobileVerificationToken).isEmpty {
            erroView.contentStr = "验证码格式错误。"
            erroView.isHidden = false
            let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                if let strongSelf = self{
                    strongSelf.erroView.isHidden = true
                }
            }
            return
        }
        switch viewMode {
        case .signUp:
            SignupService.signup(mobileCode: mobileCode, mobileNumber: mobileNumber, mobileVerificationId: mobileVerificationId,mobileVerificationToken:mobileVerificationToken, success: { [weak self] (response) in
                if let strongSelf = self {
                    strongSelf.login(token: response).then { (_) -> Void in
                        //Prevent memory leak
                        strongSelf.dismiss(animated: false, completion: {
                            if strongSelf.signupMode == SignupMode.normal {
                            } else if strongSelf.signupMode == SignupMode.continueGuestAction {
                                strongSelf.continueGuestAction()
                            } else if strongSelf.signupMode == .couponCenter {
                                Navigator.shared.dopen(Navigator.mymm.coupon_container)
                            } else if strongSelf.signupMode == .couponClaimed {
                                Navigator.shared.dopen(Navigator.mymm.website_myCoupon)
                            }
                        })
                    }
                }
                
            }) { (erro) -> Bool in
                if let userInto = erro._userInfo ,let appCode = userInto["AppCode"] as? String{
                    self.erroView.isHidden = false
                    self.erroView.contentStr = String.localize(appCode)
                    let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                        if let strongSelf = self{
                            strongSelf.erroView.isHidden = true
                        }
                    }
                }
                return true
                
            }
        case .wechat:
            SignupService.wechatSigup(mobileCode: mobileCode, mobileNumber: mobileNumber, mobileVerificationId: mobileVerificationId,mobileVerificationToken:mobileVerificationToken, success: { (response) in
                self.wechatLogin(token: response)
            }) { (erro) -> Bool in
                return true
            }

        default:
            break
        }
    }
    
    //MARK: - TextField Delegate
    func textFieldValueChanged(_ textField: PinCodeTextField) {
        if let count = textField.text?.count {
            if count == 6 {
                if let text = textField.text{
                    mobileVerificationToken = text
                }
                nextButton.isUserInteractionEnabled = true
                nextButton.backgroundColor = UIColor(hexString: "#ED2247")
                
                self.touchNextButton()
            } else{
                nextButton.isUserInteractionEnabled = false
                nextButton.backgroundColor = UIColor(hexString: "#CCCCCC")
            }
        }
    }
    
    //MARK: - Private Function
    func continueGuestAction() {
        NotificationCenter.default.post(name: Constants.Notification.continueGuestAction, object: nil)
    }
    
    func login(token:Token) -> Promise<Void> {
        LoginManager.saveLoginState(token)
        return  UserService.fetchUser(true).then { (user) -> Void in
            LoginManager.updateUserInfoAfterLogin()
            LoginManager.setUserAfterLogin(user)
            
            if token.isSignUp {
                UserService.fetchUser(true).then { (user) -> Void in
                    LoginManager.didRegister(user: user)
                    Context.clearInvitationCode()
                    LoginManager.setUserAfterLogin(user)
                    TrackManager.signUp(user.userKey)
                }
            } else {
                TrackManager.signIn(user.userKey)
            }
            NotificationCenter.default.post(name: Constants.Notification.loginSucceed, object: nil)
        }
    }
    
    func wechatLogin(token:Token)  {
        LoginManager.saveLoginState(token)
        UserService.updateDevice(
            JPUSHService.registrationID(),
            deviceIdPrevious: nil,
            completion: nil
        )
        UserService.fetchUser(true).then { [weak self] (user) -> Void in
            LoginManager.didRegister(user: user)
            LoginManager.updateUserInfoAfterLogin()
            LoginManager.setUserAfterLogin(user)
            Context.clearInvitationCode()
            TrackManager.signUp(user.userKey)
            if let strongSelf = self {
                if strongSelf.signupMode == .couponCenter {
                    Navigator.shared.dopen(Navigator.mymm.coupon_container)
                } else if strongSelf.signupMode == .couponClaimed {
                    Navigator.shared.dopen(Navigator.mymm.website_myCoupon)
                }
                strongSelf.dismiss(animated: false, completion: {
                    NotificationCenter.default.post(name: Constants.Notification.loginSucceed, object: nil)
                })
            }
            
        }
    }
}

//MARK: - AutoLayout
extension SignupSecondStepViewController {
    func createAutoLayout() {
        bgScrollView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        backButtonBackgroundView.snp.makeConstraints { (make) in
            make.left.equalTo(bgScrollView)
            make.top.equalTo(bgScrollView)
            make.height.equalTo(backButton).offset(10)
            make.width.equalTo(backButton).offset(50)
        }
        backButton.snp.makeConstraints { (make) in
            make.left.equalTo(bgScrollView).offset(20)
            make.top.equalTo(bgScrollView)
        }
        titleLabel.snp.makeConstraints { (make) in
            make.top.equalTo(backButton.snp.bottom).offset(30)
            make.left.equalTo(bgScrollView).offset(15)
        }
        topTipLabel.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.equalTo(bgScrollView).offset(15)
        }
        editButton.snp.makeConstraints { (make) in
            make.top.equalTo(titleLabel.snp.bottom)
            make.left.equalTo(topTipLabel.snp.right).offset(6)
        }
        nextButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(bgScrollView)
            make.width.equalTo(ScreenWidth - 30)
            make.height.equalTo(48)
            make.top.equalTo(restartButton.snp.bottom).offset(32)
            make.bottom.equalTo(bgScrollView).offset(-320)
        }
        textField.snp.makeConstraints { (make) in
            make.centerX.equalTo(bgScrollView)
            make.top.equalTo(titleLabel.snp.bottom).offset(65)
            make.height.equalTo(100)
            make.width.equalTo(ScreenWidth - 60)
        }
        restartButton.snp.makeConstraints { (make) in
            make.width.equalTo(ScreenWidth * 0.32)
            make.height.equalTo(32)
            make.centerX.equalTo(bgScrollView)
            make.top.equalTo(textField.snp.bottom).offset(30)
        }
        erroView.snp.makeConstraints { (make) in
            make.centerX.equalTo(bgScrollView)
            make.height.equalTo(60)
            make.top.equalTo(topTipLabel.snp.bottom).offset(5)
        }
    }
}
