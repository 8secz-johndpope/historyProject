//
//  VerficationCodeView.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
class VerificationCodeView : UIView {
    
    var viewMode = SignUpViewMode.signUp
    var signupMode = SignupMode.normal
    var button = UIButton()
    var invitationButton = UIButton()
    
    
    var viewCheckBox = UIView()
    var lineView = UIView()
    var buttonCheckbox = UIButton()
    var buttonLink = UIButton()
    var labelAnd = UILabel()
    var buttonPrivacy = UIButton()
    static let CheckBoxViewHeight : CGFloat = 30
    private var checkBoxWidth: CGFloat = 10
    static let TopMargin = CGFloat(15)
    static let InviteButtonHeight = CGFloat(30)
    static let ConfirmButtonHeight = CGFloat(42)
    
    private final let padding : CGFloat = 6
    var isShowTNC = false
    var inviteButton = UIButton()
    var enableTouch = false {
        didSet {
            if enableTouch {
                button.formatPrimary()
                inviteButton.setTitleColor(UIColor.primary1(), for: UIControlState())
                lineView.backgroundColor = UIColor.primary1()
            }else {
                button.formatDisable()
                inviteButton.setTitleColor(UIColor.secondary1(), for: UIControlState())
                lineView.backgroundColor = UIColor.secondary1()
                
            }
            button.isUserInteractionEnabled = enableTouch
            inviteButton.isUserInteractionEnabled = enableTouch
            
        }
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        lineView.backgroundColor = UIColor.primary1()
        self.addSubview(lineView)
        button.formatDisable()
        addSubview(button)
        
        let agreeString = "  " + String.localize("LB_CA_TNC_CHECK")
        buttonCheckbox.setTitle(agreeString, for: UIControlState())
        buttonCheckbox.titleLabel?.formatSize(12)
        buttonCheckbox.setTitleColor(UIColor.secondary2(), for: UIControlState())
        let iconCheckbox = UIImage(named: "square_check_box") ?? UIImage()
        checkBoxWidth = iconCheckbox.size.width
        buttonCheckbox.config(normalImage: iconCheckbox, selectedImage: UIImage(named: "square_check_box_selected"))
        buttonCheckbox.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
        buttonCheckbox.isSelected = true
        //buttonCheckbox.isHidden = true
        
        let linkString = String.localize("LB_CA_TNC_LINK")
        buttonLink.titleLabel?.formatSize(12)
        buttonLink.setTitle(linkString, for: UIControlState())
        buttonLink.setTitleColor(UIColor.black, for: UIControlState())
        //buttonLink.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
        buttonLink.backgroundColor = UIColor.clear
        buttonLink.tag = 0
        
        labelAnd.formatSize(12)
        labelAnd.text = String.localize("LB_CA_AND")
        //labelAnd.isHidden = true
        
        buttonPrivacy.titleLabel?.formatSize(12)
        buttonPrivacy.setTitle(String.localize("LB_CA_PRIVACY_POLICY"), for: UIControlState())
        buttonPrivacy.setTitleColor(UIColor.black, for: UIControlState())
        //buttonPrivacy.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Center
        buttonPrivacy.backgroundColor = UIColor.clear
        buttonPrivacy.tag = 1
        
        
        inviteButton.titleLabel?.formatSize(15)
        inviteButton.setTitle(String.localize("LB_CA_GOTO_INV_CODE_PAGE"), for: UIControlState())
        inviteButton.setTitleColor(UIColor.secondary1(), for: UIControlState())
        inviteButton.backgroundColor = UIColor.clear
        
        viewCheckBox.isHidden = true
        self.addSubview(viewCheckBox)
        
        viewCheckBox.addSubview(buttonCheckbox)
        viewCheckBox.addSubview(buttonLink)
        viewCheckBox.addSubview(labelAnd)
        viewCheckBox.addSubview(buttonPrivacy)
        
        self.addSubview(inviteButton)
        
        layout()
        
        self.enableTouch = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    func layout(){
        
        let buttonTitle = String.localize("LB_CA_CONFIRM")
        
//        switch viewMode {
//        case .SignUp:
//            buttonTitle = String.localize("LB_NEXT")
//        case .Wechat:
//            buttonTitle = String.localize("LB_CA_REGISTER")
//        case .Profile:
//            buttonTitle = String.localize("LB_CA_CONFIRM")
//        }
        button.setTitle(buttonTitle, for: UIControlState())
        if isShowTNC {
            let width = StringHelper.getTextWidth(inviteButton.titleLabel?.text ?? "", height: VerificationCodeView.InviteButtonHeight, font: inviteButton.titleLabel!.font)
            inviteButton.frame = CGRect(x: (self.bounds.sizeWidth - width) / 2, y: VerificationCodeView.TopMargin, width: width, height: VerificationCodeView.InviteButtonHeight)
            
            lineView.frame = CGRect(x: inviteButton.frame.minX, y: inviteButton.frame.maxY + CGFloat(2), width: width, height: CGFloat(1))
            
            button.frame = CGRect(x: 0, y: inviteButton.frame.maxY + VerificationCodeView.TopMargin, width: self.frame.sizeWidth, height: VerificationCodeView.ConfirmButtonHeight)
            
            self.lineView.isHidden = false
            self.viewCheckBox.isHidden = false
            self.inviteButton.isHidden = false
            self.viewCheckBox.frame =  CGRect(x: 0, y: button.frame.maxY + 5 , width: bounds.width, height: VerificationCodeView.CheckBoxViewHeight)
            
            if let textFont = self.buttonCheckbox.titleLabel?.font, let linkTextFont = self.buttonLink.titleLabel?.font , let privacyFont = self.buttonPrivacy.titleLabel?.font{
                let postY: CGFloat = 0
                let marginLeft : CGFloat = 3
                let agreeWidth = StringHelper.getTextWidth(self.buttonCheckbox.titleLabel?.text ?? "", height: VerificationCodeView.CheckBoxViewHeight, font: textFont)
                let linkWidth = StringHelper.getTextWidth(self.buttonLink.titleLabel?.text ?? "", height: VerificationCodeView.CheckBoxViewHeight, font: linkTextFont)
                let andWidth = StringHelper.getTextWidth(labelAnd.text ?? "", height: VerificationCodeView.CheckBoxViewHeight, font: labelAnd.font)
                let privacyWidth = StringHelper.getTextWidth(self.buttonPrivacy.titleLabel?.text ?? "", height: VerificationCodeView.CheckBoxViewHeight, font: privacyFont)
                
                buttonCheckbox.frame = CGRect(x: 0, y: postY , width: checkBoxWidth + agreeWidth, height: VerificationCodeView.CheckBoxViewHeight)
                buttonLink.frame = CGRect(x: buttonCheckbox.frame.maxX + marginLeft, y: postY , width: linkWidth, height: VerificationCodeView.CheckBoxViewHeight)
                
                labelAnd.frame = CGRect(x: buttonLink.frame.maxX + marginLeft, y: postY , width: andWidth, height: VerificationCodeView.CheckBoxViewHeight)
                
                buttonPrivacy.frame = CGRect(x: labelAnd.frame.maxX + marginLeft, y: postY , width: privacyWidth, height: VerificationCodeView.CheckBoxViewHeight)
                
            }
            
        } else {
            self.lineView.isHidden = true
            self.viewCheckBox.isHidden = true
            self.inviteButton.isHidden = true
            button.frame = CGRect(x: bounds.minX, y: 0, width: bounds.width, height: VerificationCodeView.ConfirmButtonHeight)
        }
		
    }

    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
