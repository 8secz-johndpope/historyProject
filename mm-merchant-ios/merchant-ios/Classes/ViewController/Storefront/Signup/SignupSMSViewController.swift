//
//  SignupSMSViewController.swift
//  storefront-ios
//
//  Created by Kam on 8/9/2018.
//  Copyright © 2018 WWE & CO. All rights reserved.
//

import UIKit
import YYText
import PromiseKit

enum SMSFlowStep: Int {
    case mobileNumber = 0,
    smsCode
}

class SignupSMSViewController: MMUIController, UITextFieldDelegate {
    private var mobileCode: String = "+86"
    private var mobileNumber: String = ""
    private var mobileVerificationId: String = ""
    private var mobileVerificationToken: String = ""
    private let _data = ["+86","+852"]
    open var viewMode: SignUpViewMode = .signUp
    private var currentStep = SMSFlowStep.mobileNumber
    private static let interval = 0.35
    
    public var loginAfterCompletion: LoginAfterCompletion?
    
    //MARK: - Life cycle
    public override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        self.view.backgroundColor = .white
        
        self.view.addSubview(bgScrollView)
        bgScrollView.addSubview(backButtonBackgroundView)
        bgScrollView.addSubview(backButton)
        bgScrollView.addSubview(titleLabel)
        bgScrollView.addSubview(topTipLabel)
        bgScrollView.addSubview(editButton)
        bgScrollView.addSubview(loginPhone)
        bgScrollView.addSubview(nextButton)
        bgScrollView.addSubview(bottomTipLabel)
        bgScrollView.addSubview(chooseView)
        
        bgScrollView.addSubview(textField)
        bgScrollView.addSubview(restartButton)
        
        bgScrollView.addSubview(errorView)
        
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
    @objc func touchLoagin()  {
        self.chooseView.isHidden = !self.chooseView.isHidden
    }
    
    @objc func touchBackButton()  {
        Alert.alert(self, title: "", message: String.localize("LB_CA_SIGNUP_CANCEL"), okActionComplete: { () -> Void in
            self.navigationController?.popViewController(animated: true)
        }, cancelActionComplete:nil)
    }
    
    @objc func touchNextButton()  {
        
        switch currentStep {
        case .mobileNumber:
            if !(mobileCode == _data[1] && RegexManager.isHKMobile(mobileNumber)) && !(mobileCode == _data[0] && RegexManager.isChinaMobile(mobileNumber))  {
                errorView.contentStr =  String.localize("MSG_ERR_CA_MOBILE_PATTERN")
                errorView.isHidden = false
                let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                    if let strongSelf = self{
                        strongSelf.errorView.isHidden = true
                    }
                }
                return
            }
            
            self.nextButton.isEnabled = false
            
            SignupService.getsms(mobileCode: mobileCode, mobileNumber: mobileNumber, success: { (model) in
                self.mobileVerificationId = String(model.mobileVerificationId)
                self.moveToNextStep()
            }) { (erro) -> Bool in
                if let userInto = erro._userInfo ,let appCode = userInto["AppCode"] as? String{
                    self.errorView.isHidden = false
                    self.errorView.contentStr = String.localize(appCode)
                    self.nextButton.isEnabled = true
                    let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                        if let strongSelf = self{
                            strongSelf.errorView.isHidden = true
                        }
                    }
                }
                return true
            }
        case .smsCode:
            let regexText = "^[0-9]+$"
            if RegexManager.matchesForRegexInText(regexText, text: mobileVerificationToken).isEmpty {
                errorView.contentStr = "验证码格式错误。"
                errorView.isHidden = false
                let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                    if let strongSelf = self {
                        strongSelf.errorView.isHidden = true
                    }
                }
                return
            }
            
            let loginCompletion = {
                self.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: Constants.Notification.loginSucceed, object: nil)
                    if let loginAfterBlock = self.loginAfterCompletion {
                        loginAfterBlock()
                    }
                })
            }
            if self.viewMode == .wechat {
                SignupService.wechatSigup(mobileCode: mobileCode, mobileNumber: mobileNumber, mobileVerificationId: mobileVerificationId,mobileVerificationToken:mobileVerificationToken, success: { [weak self] (response) in
                    UserService.updateDevice(
                        JPUSHService.registrationID(),
                        deviceIdPrevious: nil,
                        completion: nil
                    )
                    if let strongSelf = self {
                        strongSelf.login(token: response).then { (_) -> Void in
                            loginCompletion()
                        }
                    }
                }) { (erro) -> Bool in
                    return true
                }
            } else {
                SignupService.signup(mobileCode: mobileCode, mobileNumber: mobileNumber, mobileVerificationId: mobileVerificationId, mobileVerificationToken: mobileVerificationToken, success: { [weak self] (response) in
                    if let strongSelf = self {
                        strongSelf.login(token: response).then { (_) -> Void in
                            strongSelf.dismiss(animated: true, completion: {
                                loginCompletion()
                            })
                        }
                    }
                }) { (erro) -> Bool in
                    if let userInto = erro._userInfo ,let appCode = userInto["AppCode"] as? String{
                        self.errorView.isHidden = false
                        self.errorView.contentStr = String.localize(appCode)
                        let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                        DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                            if let strongSelf = self{
                                strongSelf.errorView.isHidden = true
                            }
                        }
                    }
                    return true
                }
            }
        }
        
    }
    
    private func login(token:Token) -> Promise<Void> {
        LoginManager.saveLoginState(token)
        return UserService.fetchUser(true).then { (user) -> Void in
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
        }
    }
    
    //MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        if textField == loginPhone.textField {
            let newLength = text.utf16.count + string.utf16.count - range.length
            let changeText = (text as NSString).replacingCharacters(in: range, with: string)
            return checkMobileNumber(newLength: newLength, changeText: changeText as String)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        nextButton.isEnabled = false
        return true
    }
    
    func checkMobileNumber(newLength:Int,changeText:String) -> Bool {
        var number = 11
        if mobileCode == _data[0]{
            number = 11
        }else if mobileCode == _data[1]{
            number = 8
        }
        if newLength < number {
            nextButton.isEnabled = false
        } else {
            nextButton.isEnabled = true
            mobileNumber = changeText
        }
        
        if newLength > number - 1 {
            loginPhone.textField.text = (changeText as NSString).substring(to: number)
            mobileNumber = (changeText as NSString).substring(to: number)
            loginPhone.textField.resignFirstResponder()
        }
        return newLength < number
    }
    
    private func backToFirstStep() {
        currentStep = .mobileNumber
        topTipLabel.isHidden = true
        animationCountryCode.isHidden = false
        animationPhoneNumber.isHidden = false
        textField.isHidden = true
        editButton.isHidden = true
        textField.resignFirstResponder()
        textField.text = ""
        
        UIView.animate(withDuration: SignupSMSViewController.interval, animations: {
            self.animateLabel(toStep: .mobileNumber)
        }) { (completed) in
            if completed {
                self.animationCountryCode.isHidden = true
                self.animationPhoneNumber.isHidden = true
                self.topTipLabel.isHidden = false
                self.topTipLabel.text = String.localize("LB_CA_SIGNINUP_NEWBIE_COUPON_INFO") //with animation
                self.loginPhone.isHidden = false
                self.nextButton.isHidden = false
                self.restartButton.isHidden = true
                self.restartButton.cancelCountdown()
                self.nextButton.isEnabled = true //enable it when mobile phone number done
                self.loginPhone.textField.text = self.mobileNumber
            }
        }
    }
    
    //MARK: - SMS Verification Second Step
    private func moveToNextStep() {
        currentStep = .smsCode
        self.loginPhone.isHidden = true
        self.nextButton.isHidden = true
        
        if animationCountryCode.superview == nil {
            bgScrollView.addSubview(animationCountryCode)
        }
        if animationPhoneNumber.superview == nil {
            bgScrollView.addSubview(animationPhoneNumber)
        }
        topTipLabel.isHidden = true
        animationCountryCode.text = "\(self.mobileCode)"
        animationPhoneNumber.text = self.mobileNumber
        animationCountryCode.isHidden = false
        animationPhoneNumber.isHidden = false
        
        UIView.animate(withDuration: SignupSMSViewController.interval, animations: {
            self.animateLabel(toStep: .smsCode)
        }) { (completed) in
            if completed {
                self.animationCountryCode.isHidden = true
                self.animationPhoneNumber.isHidden = true
                self.topTipLabel.isHidden = false
                self.topTipLabel.text = "(\(self.mobileCode))\(self.mobileNumber)" //with animation
                self.editButton.isHidden = false
                self.textField.isHidden = false
                self.restartButton.isHidden = false
                self.restartButton.setCountdown(60)
                self.textField.becomeFirstResponder()
            }
        }
    }
    
    private func animateLabel(toStep: SMSFlowStep) {
        switch toStep {
        case .mobileNumber:
            animationCountryCode.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            animationCountryCode.frame = CGRect(x: loginPhone.label.x + loginPhone.x + 24, y: loginPhone.frame.origin.y, width: loginPhone.label.frame.width, height: loginPhone.label.frame.height)
            
            animationPhoneNumber.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            animationPhoneNumber.frame = CGRect(x: loginPhone.textField.x + loginPhone.x, y: loginPhone.frame.origin.y, width: loginPhone.frame.width, height: loginPhone.frame.height)
        case .smsCode:
            animationCountryCode.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            animationCountryCode.frame = CGRect(x: bgScrollView.origin.x, y: topTipLabel.origin.y, width: animationCountryCode.frame.width, height: topTipLabel.frame.height)
            
            animationPhoneNumber.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            animationPhoneNumber.frame = CGRect(x: bgScrollView.origin.x + animationCountryCode.frame.width - 10, y: topTipLabel.origin.y, width: animationPhoneNumber.frame.width, height: topTipLabel.frame.height)
        }
    }
    
    @objc func touchRestartButton()  {
        restartButton.setCountdown(60)
        SignupService.getsms(mobileCode: mobileCode, mobileNumber: mobileNumber, success: { (model) in
            self.mobileVerificationId = String(model.mobileVerificationId)
        }) { (erro) -> Bool in
            return true
        }
    }
    
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
        titleLabel.text = String.localize("LB_CA_SIGN_UP_IN")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        return titleLabel
    }()
    
    lazy var topTipLabel:UILabel = {
        let topTipLabel = UILabel()
        topTipLabel.text = String.localize("LB_CA_SIGNINUP_NEWBIE_COUPON_INFO")
        topTipLabel.font = UIFont.systemFont(ofSize: 16)
        topTipLabel.textColor = UIColor.secondary17()
        return topTipLabel
    }()
    
    lazy var editButton: UIButton = {
        let edit = UIButton()
        edit.setImage(UIImage(named: "sms_edit"), for: .normal)
        edit.isHidden = true
        edit.whenTapped {
            self.backToFirstStep()
        }
        return edit
    }()
    
    lazy var loginPhone:SignupLoginPhoneView = {
        let loginPhone = SignupLoginPhoneView()
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(touchLoagin))
        loginPhone.tapView.addGestureRecognizer(tapGesture)
        loginPhone.textField.becomeFirstResponder()
        loginPhone.textField.delegate = self
        return loginPhone
    }()
    
    lazy var nextButton:UIButton = {
        let nextButton = UIButton()
        nextButton.setTitleColor(.white, for: UIControlState.normal)
        nextButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        nextButton.isEnabled = false
        //        nextButton.backgroundColor = UIColor(hexString: "#CCCCCC")
        nextButton.layer.cornerRadius = 4.0
        nextButton.layer.masksToBounds = true
        nextButton.setTitle(String.localize("LB_CA_SIGNUPIN_GET_CODE"), for: .normal)
        nextButton.setBackgroundImageColor(UIColor(hexString: "#ED2247"), for: .normal)
        nextButton.setBackgroundImageColor(UIColor(hexString: "#CCCCCC"), for: .disabled)
        nextButton.addTarget(self, action: #selector(touchNextButton), for: .touchUpInside)
        return nextButton
    }()
    
    lazy var bottomTipLabel:YYLabel = {
        let bottomTipLabel = YYLabel()
        bottomTipLabel.font = UIFont.systemFont(ofSize: 12)
        bottomTipLabel.textColor = UIColor.lightGray
        let attributedString:NSMutableAttributedString = NSMutableAttributedString.init(string: "注册即代表你已阅读并接受 美美用户注册协议 及 隐私权政策")
        attributedString.yy_setTextHighlight(NSMakeRange(attributedString.length - 5 - 3 - 8, 8), color: UIColor(hexString: "#507DAF"), backgroundColor: UIColor.lightGray, tapAction: { [weak self] (view: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            if let strongSelf = self {
                if let url = ContentURLFactory.urlForContentType(.mmUserAgreement) {
                    strongSelf.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_TNC"), urlGetContentPage: url), animated: true)
                }
            }
            }, longPressAction: nil)
        attributedString.yy_setTextHighlight(NSMakeRange(attributedString.length - 5, 5), color: UIColor(hexString: "#507DAF"), backgroundColor: UIColor.lightGray, tapAction: { [weak self] (view: UIView, text: NSAttributedString, range: NSRange, rect: CGRect) in
            if let strongSelf = self {
                if let url = ContentURLFactory.urlForContentType(.mmPrivacyStatement) {
                    strongSelf.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_PRIVACY_POLICY"), urlGetContentPage: url), animated: true)
                }
            }
            }, longPressAction: nil)
        bottomTipLabel.attributedText = attributedString
        bottomTipLabel.textAlignment = .center
        bottomTipLabel.numberOfLines = 0
        return bottomTipLabel
    }()
    
    lazy var chooseView:SignupChooseView = {
        let chooseView = SignupChooseView()
        chooseView.backgroundColor = UIColor.clear
        chooseView.isHidden = true
        chooseView.tapHandler = {[weak self] (title,index) in
            if let strongSelf = self {
                chooseView.isHidden = !chooseView.isHidden
                strongSelf.loginPhone.label.text = title
                strongSelf.mobileCode = strongSelf._data[index]
            }
        }
        return chooseView
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
        restartButton.isHidden = true
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
        textField.underlineHeight = 3
        textField.font = UIFont.systemFont(ofSize: 47)
        textField.isHidden = true
        textField.delegate = self
        return textField
    }()
    
    lazy var errorView:SignupErroView = {
        let errorView = SignupErroView()
        errorView.contentStr =  String.localize("MSG_ERR_CA_MOBILE_PATTERN")
        errorView.isHidden = true
        return errorView
    }()
    
    lazy var animationCountryCode: UILabel = {
        let label = UILabel(frame: CGRect(x: loginPhone.label.x + loginPhone.x + 24, y: loginPhone.frame.origin.y, width: loginPhone.label.frame.width, height: loginPhone.label.frame.height))
        label.font = loginPhone.textField.font
        label.textColor = UIColor.secondary17()
        label.textAlignment = .center
        return label
    }()
    
    lazy var animationPhoneNumber: UILabel = {
        let label = UILabel(frame: CGRect(x: loginPhone.textField.x + loginPhone.x, y: loginPhone.frame.origin.y, width: loginPhone.frame.width, height: loginPhone.frame.height))
        label.font = loginPhone.textField.font
        label.textColor = UIColor.secondary17()
        label.textAlignment = .left
        return label
    }()
    
}

extension SignupSMSViewController: PinCodeTextFieldDelegate {
    //MARK: - TextField Delegate
    func textFieldValueChanged(_ textField: PinCodeTextField) {
        if let count = textField.text?.count {
            if count == 6 {
                if let text = textField.text{
                    mobileVerificationToken = text
                }
                nextButton.isEnabled = true
                
                self.touchNextButton()
            } else{
                nextButton.isEnabled = false
            }
        }
    }
}

//MARK: - AutoLayout
extension SignupSMSViewController {
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
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.left.equalTo(topTipLabel.snp.right).offset(6)
        }
        loginPhone.snp.makeConstraints { (make) in
            make.top.equalTo(topTipLabel.snp.bottom).offset(94)
            make.left.right.width.equalTo(self.view)
            make.height.equalTo(50)
        }
        nextButton.snp.makeConstraints { (make) in
            make.centerX.equalTo(bgScrollView)
            make.top.equalTo(loginPhone.snp.bottom).offset(80)
            make.width.equalTo(ScreenWidth - 30)
            make.height.equalTo(48)
        }
        bottomTipLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(bgScrollView)
            make.top.equalTo(nextButton.snp.bottom).offset(8)
            make.bottom.equalTo(bgScrollView).offset(-320)
            make.left.equalTo(15)
            make.right.equalTo(-15)
        }
        chooseView.snp.makeConstraints { (make) in
            make.left.equalTo(loginPhone).offset(13)
            make.width.equalTo(ScreenWidth * 0.38)
            make.height.equalTo(96)
            make.top.equalTo(loginPhone.snp.bottom).offset(-15)
        }
        errorView.snp.makeConstraints { (make) in
            make.centerX.equalTo(bgScrollView)
            make.top.equalTo(topTipLabel.snp.bottom)
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
    }

}
