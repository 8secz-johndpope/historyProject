//
//  SignupInputView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
enum SignupTextFieldTag: Int {
    case countryCode = 1
    case phoneNumber = 2
    case countryName = 3
    case verificationCode = 4
}

protocol RequestSMSDelegate : NSObjectProtocol{
    
    func startSMS()
    func resetSMS()
    func validatePhoneNumber() -> Bool
    
}
class SignupInputView : UIView {
    
    var inputBackground = UIImageView ()
    var countryLabel = UILabel()
    var codeTextField = UITextField()
    var countryTextField = UITextField()
    var countryButton = UIButton()
    var mobileNumberTextField = UITextField()
    
    var iconImageView = UIImageView()
    var activeCodeTextField = UITextField()
    var countryLineView = UIView()
    var phoneNumberLineView = UIView()
    var requestSMSButton = UIButton()
    
    
    var countryLineViewVertical = UIView()
    var phoneLineViewVertical = UIView()
    
    
    var isCountingDown = false
    private var dateTime = Date()
    private var timer : Timer?
    var timeCountdown : CGFloat = 60
    
    var borderTF = UITextField()
    var delegate: RequestSMSDelegate?
    
    final let ShortLabelWidth : CGFloat = 75
    final let LabelHeight : CGFloat = 46
    final let PhoneNumberHeight = CGFloat(54)
    final let Margin : CGFloat = 10
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        
        inputBackground.layer.borderColor = UIColor.secondary1().cgColor
        inputBackground.layer.borderWidth = CGFloat(1)
        
        countryLineView.backgroundColor = UIColor.secondary1()
        self.addSubview(countryLineView)
        
        phoneNumberLineView.backgroundColor = UIColor.secondary1()
        self.addSubview(phoneNumberLineView)
        
        phoneLineViewVertical.backgroundColor = UIColor.secondary1()
        self.addSubview(phoneLineViewVertical)
        
        countryLineViewVertical.backgroundColor = UIColor.secondary1()
        self.addSubview(countryLineViewVertical)
        
        addSubview(inputBackground)
        countryLabel.textAlignment = .center
        countryLabel.formatSize(14)
        countryLabel.text = String.localize("LB_CA_IDD_REGION")
        addSubview(countryLabel)
        
        codeTextField.textAlignment = .left
        addSubview(codeTextField)
        
        
        
        self.addSubview(borderTF)
        borderTF.layer.borderColor = UIColor.primary1().cgColor
        borderTF.layer.borderWidth = 1
        borderTF.tag = Constants.TextField.OverlayTag
        borderTF.isUserInteractionEnabled = false
        borderTF.isHidden = true
        
        addSubview(countryButton)
        addSubview(mobileNumberTextField)
        countryButton.formatTransparent()
        countryButton.layer.borderWidth = 0
        countryButton.titleLabel?.formatSize(14)
        countryButton.setTitleColor(UIColor.secondary2(), for: UIControlState())
        countryButton.contentHorizontalAlignment = .left
        countryButton.setTitle(String.localize("LB_COUNTRY_PICK"), for: UIControlState())
        
        countryTextField.formatTransparent()
        countryTextField.tag = SignupTextFieldTag.countryName.rawValue
        countryTextField.placeholder = String.localize("LB_COUNTRY_PICK")
        countryTextField.isHidden = true
        countryTextField.accessibilityIdentifier = "country_name_textfield"
        addSubview(countryTextField)
        
        mobileNumberTextField.placeholder = String.localize("LB_CA_INPUT_MOBILE")
        mobileNumberTextField.keyboardType = .phonePad
        mobileNumberTextField.formatTransparent()
        codeTextField.keyboardType = .numberPad
        codeTextField.formatTransparentValidate()
        codeTextField.tag = SignupTextFieldTag.countryCode.rawValue
        mobileNumberTextField.tag = SignupTextFieldTag.phoneNumber.rawValue
        
        activeCodeTextField.keyboardType = .numberPad
        activeCodeTextField.placeholder = String.localize("LB_CA_INPUT_VERCODE")
        activeCodeTextField.formatTransparent()
        activeCodeTextField.tag = SignupTextFieldTag.verificationCode.rawValue
        addSubview(activeCodeTextField)
        
        requestSMSButton.setTitleColor(UIColor.secondary1(), for: UIControlState())
        requestSMSButton.titleLabel?.formatSize(14)
        requestSMSButton.setTitle(String.localize("LB_CA_SR_REQUEST_VERCODE"), for: UIControlState())
        requestSMSButton.addTarget(self, action: #selector(SignupInputView.requestSMS), for: .touchUpInside)
        self.addSubview(requestSMSButton)
        
        iconImageView.image = UIImage(named: "filter_right_arrow")
        self.addSubview(iconImageView)
        
        self.setEnableRequestSMSButton(true, titleColor: nil)
        layout()
    }
    
    func setEnableRequestSMSButton(_ enable: Bool,titleColor : UIColor?) {
        self.requestSMSButton.isEnabled = enable
        if let color = titleColor {
            requestSMSButton.setTitleColor(color, for: UIControlState())
        }else {
            requestSMSButton.setTitleColor(enable ? UIColor.primary1() : UIColor.secondary1(), for: UIControlState())
        }
    }
    
    @objc func requestSMS(_ sender: UIButton) {
        self.startSMS()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    func layout(){
        inputBackground.frame = bounds
        
        let paddingTop = CGFloat(5)
        countryLabel.frame = CGRect(x: 0, y: 0, width: ShortLabelWidth, height: LabelHeight)
        countryLineViewVertical.frame = CGRect(x: ShortLabelWidth, y: paddingTop, width: CGFloat(1), height: LabelHeight - 2 * paddingTop)
        countryLineView.frame = CGRect(x: 0, y: LabelHeight, width: self.frame.width, height: 1)
        
        var width = CGFloat(0)
        if let titleLabel = requestSMSButton.titleLabel {
            width = StringHelper.getTextWidth(titleLabel.text ?? "", height: LabelHeight, font: titleLabel.font)
            requestSMSButton.frame = CGRect(x: self.bounds.sizeWidth - Margin - width, y: LabelHeight, width: width, height: LabelHeight)
        }
        
        let margin = CGFloat(6)
        codeTextField.frame = CGRect(x: margin, y: LabelHeight, width: ShortLabelWidth - margin, height: LabelHeight)
        
        phoneLineViewVertical.frame = CGRect(x: ShortLabelWidth, y: LabelHeight + paddingTop, width: CGFloat(1), height: LabelHeight - 2 * paddingTop)
        
        borderTF.frame = CGRect(x: 0, y: LabelHeight + 1, width: self.frame.width, height: LabelHeight + 1)
        
        countryButton.frame = CGRect(x: ShortLabelWidth + Margin, y: 0, width: bounds.width - (ShortLabelWidth + Margin * 2) , height: LabelHeight)
        countryTextField.frame = CGRect(x: ShortLabelWidth + Margin, y: 0, width: bounds.width - (ShortLabelWidth + Margin * 2), height: LabelHeight)
        
        let iconSize = CGSize(width: 7, height: 14)
        iconImageView.frame = CGRect(x: self.bounds.sizeWidth - Margin - iconSize.width, y: countryTextField.frame.midY - iconSize.height / 2, width: iconSize.width, height: iconSize.height)

        mobileNumberTextField.frame = CGRect(x: ShortLabelWidth + Margin , y: LabelHeight, width: bounds.width - ShortLabelWidth - Margin * 2 - width, height: LabelHeight)
        
        phoneNumberLineView.frame = CGRect(x: 0, y: mobileNumberTextField.frame.maxY, width: self.frame.width, height: 1)
        
        activeCodeTextField.frame = CGRect(x: 0 , y: phoneNumberLineView.frame.maxY, width: self.frame.width, height: LabelHeight)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func hideCountryButton(_ isHiden: Bool) {
        self.countryButton.isHidden = isHiden
        self.countryTextField.isHidden = !isHiden
    }
    
    func startSMS() {
        if let sigupDelegate = self.delegate {
            if sigupDelegate.validatePhoneNumber() {
                sigupDelegate.startSMS()
                dateTime = Date()
                
                timer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(SignupInputView.update), userInfo: nil, repeats: true)
                isCountingDown = true
                self.setEnableRequestSMSButton(false, titleColor: nil)
                requestSMSButton.setTitle(self.getSMSText(Int(timeCountdown)), for: UIControlState())
                self.layout()
            }
        }
    }
    
    func reset() {
        self.resetWithoutCallback()
        self.delegate?.resetSMS()
    }
    
    func resetWithoutCallback() {
        
        requestSMSButton.setTitle(String.localize("LB_CA_SR_REQUEST_VERCODE"), for: UIControlState())
        self.setEnableRequestSMSButton(true, titleColor: UIColor.primary1())
        if let timer = self.timer {
            timer.invalidate()
        }
        timer = nil
        isCountingDown = false
        self.layout()
    }
    
    func isTimerCounting() -> Bool {
        return isCountingDown
    }
    
    func getSMSText(_ remainingTime: Int) -> String {
        return "(\(remainingTime))" + String.localize("LB_CA_SR_REQUEST_VERCODE_SENT_2")
    }
    
    @objc internal func update() {
        let time = CGFloat(dateTime.timeIntervalSinceNow)
        let remainingTime = timeCountdown + time
        if remainingTime <= 0 {
            self.reset()
        }
        else {
            requestSMSButton.setTitle(self.getSMSText(Int(remainingTime)), for: UIControlState())
            setEnableRequestSMSButton(false, titleColor: nil)
            self.layout()
        }
    }
    
}
