//
//  SignupViewController.swift
//  storefront-ios
//
//  Created by Leslie Zhang on 2018/4/26.
//  Copyright © 2018年 WWE & CO. All rights reserved.
//

import UIKit
import YYText

class SignupFirstStepViewController: MMUIController,UITextFieldDelegate{
    var mobileCode:String = "+86"
    var mobileNumber:String = ""
    var mobileVerificationId:String = ""
    let _data = ["+86","+852"]
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
        titleLabel.text = String.localize("LB_CA_SIGN_UP_IN")
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        return titleLabel
    }()
    lazy var topTipLabel:UILabel = {
        let topTipLabel = UILabel()
        topTipLabel.text = String.localize("LB_CA_SIGNINUP_NEWBIE_COUPON_INFO")
        topTipLabel.font = UIFont.systemFont(ofSize: 12)
        topTipLabel.textColor = UIColor.secondary17()
        return topTipLabel
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
        nextButton.backgroundColor = UIColor(hexString: "#CCCCCC")
        nextButton.layer.cornerRadius = 4.0
        nextButton.layer.masksToBounds = true
        nextButton.setTitle(String.localize("LB_NEXT"), for: UIControlState.normal)
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
        return textField
    }()
    lazy var erroView:SignupErroView = {
        let erroView = SignupErroView()
        erroView.contentStr =  String.localize("MSG_ERR_CA_MOBILE_PATTERN")
        erroView.isHidden = true
        return erroView
    }()

    //MARK: - Life cycle
    public override func onLoadView() -> Bool {
        self.view = UIView(frame:UIScreen.main.bounds)
        self.view.backgroundColor = .white
        
        self.view.addSubview(bgScrollView)
        bgScrollView.addSubview(backButtonBackgroundView)
        bgScrollView.addSubview(backButton)
        bgScrollView.addSubview(titleLabel)
        bgScrollView.addSubview(topTipLabel)
        bgScrollView.addSubview(loginPhone)
        bgScrollView.addSubview(nextButton)
        bgScrollView.addSubview(bottomTipLabel)
        bgScrollView.addSubview(chooseView)
        bgScrollView.addSubview(erroView)
        
        return true
    }
    public override func onViewDidLoad() {
        super.onViewDidLoad()
        
        createAutoLayout()
    }
    
    deinit {
        
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
        if !(mobileCode == _data[1] && RegexManager.isHKMobile(mobileNumber))
            && !(mobileCode == _data[0] && RegexManager.isChinaMobile(mobileNumber))  {
            erroView.contentStr =  String.localize("MSG_ERR_CA_MOBILE_PATTERN")
            erroView.isHidden = false
            let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                if let strongSelf = self{
                    strongSelf.erroView.isHidden = true
                }
            }
            return
        }
        
        self.nextButton.isUserInteractionEnabled = false
        
        SignupService.getsms(mobileCode: mobileCode, mobileNumber: mobileNumber, success: { (model) in
            self.mobileVerificationId = String(model.mobileVerificationId)
            let signupViewController = SignupSecondStepViewController()
            signupViewController.mobileCode = self.mobileCode
            signupViewController.mobileNumber = self.mobileNumber
            signupViewController.mobileVerificationId = self.mobileVerificationId
            signupViewController.viewMode = self.viewMode
            signupViewController.signupMode = self.signupMode
            self.nextButton.isUserInteractionEnabled = true
            self.navigationController?.push(signupViewController, animated: true)
        }) { (erro) -> Bool in
            if let userInto = erro._userInfo ,let appCode = userInto["AppCode"] as? String{
                self.erroView.isHidden = false
                self.erroView.contentStr = String.localize(appCode)
                self.nextButton.isUserInteractionEnabled = true
                let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delayTime) { [weak self] in
                    if let strongSelf = self{
                        strongSelf.erroView.isHidden = true
                    }
                }
            }
            return true
        }
    }
    
    //MARK: - UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        
        if textField == loginPhone.textField{
            let newLength = text.utf16.count + string.utf16.count - range.length
            let changeText = (text as NSString).replacingCharacters(in: range, with: string)
            return checkMobileNumber(newLength: newLength, changeText: changeText as String)
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        nextButton.backgroundColor = UIColor(hexString: "#CCCCCC")
        return true
    }
    
    func checkMobileNumber(newLength:Int,changeText:String) -> Bool {
        var number = 11
        if mobileCode == _data[0]{
           number = 11
        }else if mobileCode == _data[1]{
           number = 8
        }
        if newLength < number{
            nextButton.backgroundColor = UIColor(hexString: "#CCCCCC")
            nextButton.isUserInteractionEnabled = false
        }else {
            nextButton.backgroundColor = UIColor(hexString: "#ED2247")
            nextButton.isUserInteractionEnabled = true
            mobileNumber = changeText
        }
        
        if newLength > number - 1 {
            loginPhone.textField.text = (changeText as NSString).substring(to: number)
            mobileNumber = (changeText as NSString).substring(to: number)
            loginPhone.textField.resignFirstResponder()
        }
        return newLength < number
    }
}

//MARK: - AutoLayout
extension SignupFirstStepViewController {
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
        erroView.snp.makeConstraints { (make) in
            make.centerX.equalTo(bgScrollView)
            make.top.equalTo(topTipLabel.snp.bottom).offset(15)
        }
    }
}


