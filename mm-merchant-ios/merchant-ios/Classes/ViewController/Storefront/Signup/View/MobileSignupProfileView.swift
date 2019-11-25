//
//  MobileSignupProfileView.swift
//  merchant-ios
//
//  Created by Sang on 2/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}



class MobileSignupProfileView: UIView {
    private final let InputViewMarginLeft : CGFloat = 20
    private final let ShortLabelWith : CGFloat = 85
    private final let LabelHeight : CGFloat = 47
    private final let ViewAvatarWidth : CGFloat = 93
    private final let ImageAvatarWidth : CGFloat = 44
    private final let InputBoxHeight : CGFloat = 48
    private final let TextFieldMarginLeft : CGFloat = 10
    var usernameTextField = UITextField()
    var displaynameTextField = UITextField()
    var passwordTextField = UITextField()
    var passwordConfirmTextField = UITextField()
    var avatarImageView = UIImageView()
    var checkboxButton = UIButton()
    var linkButton = UIButton()
    var avatarView = UIView()
    var inputView1 = UIView()
    var inputBackground = UIImageView()
    var displaynameLabel = UILabel()
    var usernameLabel = UILabel()
    var profileLabel = UILabel()
    var inputView2 = UIView()
    var imagePassword = UIImageView()
    var imagePasswordConfirm = UIImageView()
    var imageCheckbox = UIImage(named: "square_check_box") ?? UIImage()
    var registerButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        let profileInputImage = UIImage(named: "mobile_signup_input_profile")
        profileInputImage?.resizableImage(withCapInsets: UIEdgeInsets(top: 20, left: 90, bottom: 20, right: 200))
        inputBackground.image = profileInputImage
        inputView1.addSubview(inputBackground)
       
        usernameLabel.textAlignment = .center
        usernameLabel.formatSize(14)
        usernameLabel.text = String.localize("LB_CA_USERNAME")
        inputView1.addSubview(usernameLabel)
        
        usernameTextField.textAlignment = .left
        usernameTextField.textColor = UIColor.secondary2()
        usernameTextField.font = UIFont.systemFont(ofSize: 14)
        usernameTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        inputView1.addSubview(usernameTextField)
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.tag = 1
        displaynameLabel.textAlignment = .center
        displaynameLabel.formatSize(14)
        displaynameLabel.text = String.localize("LB_CA_DISPNAME")
        inputView1.addSubview(displaynameLabel)

        displaynameTextField.textAlignment = .left
        displaynameTextField.tag = 2
        displaynameTextField.textColor = UIColor.secondary2()
        displaynameTextField.font = UIFont.systemFont(ofSize: 14)
        displaynameTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        inputView1.addSubview(displaynameTextField)
        displaynameTextField.autocapitalizationType = .none
        displaynameTextField.autocorrectionType = .no
        
        //Create avatar view
        avatarView.backgroundColor = UIColor.clear
        avatarImageView.image = UIImage(named: Constants.ImageName.ProfileImagePlaceholder)
        avatarImageView.isUserInteractionEnabled = true;
        avatarImageView.round()
        avatarView.addSubview(avatarImageView)
        
        profileLabel.textAlignment = .center
        profileLabel.formatSize(14)
        profileLabel.text = String.localize("LB_CA_PROFILE_PIC")
        avatarView.addSubview(profileLabel)
        inputView1.addSubview(avatarView)
        self.addSubview(inputView1)

        let inputBoxSingle = UIImage(named: "input_box_single")
        inputBoxSingle?.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        imagePassword.image = inputBoxSingle
        imagePasswordConfirm.image = inputBoxSingle
//        inputView2.addSubview(imagePassword)
//        inputView2.addSubview(imagePasswordConfirm)
        
        
        //Create password
        passwordTextField.textAlignment = .left
        passwordTextField.textColor = UIColor.secondary2()
        passwordTextField.font = UIFont.systemFont(ofSize: 14)
        passwordTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        passwordTextField.isSecureTextEntry = true
        passwordTextField.tag = 3
        passwordTextField.placeholder = String.localize("LB_ENTER_PW")
        passwordTextField.format()
        inputView2.addSubview(passwordTextField)

        //Create password confirm
        passwordConfirmTextField.textAlignment = .left
        passwordConfirmTextField.textColor = UIColor.secondary2()
        passwordConfirmTextField.font = UIFont.systemFont(ofSize: 14)
        passwordConfirmTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        passwordConfirmTextField.isSecureTextEntry = true
        passwordConfirmTextField.placeholder = String.localize("LB_CA_CONF_PW")
        passwordConfirmTextField.tag = 4
        passwordConfirmTextField.format()
        inputView2.addSubview(passwordConfirmTextField)
        self.addSubview(inputView2)
        
        //Create checkbox button
        checkboxButton.setImage(imageCheckbox, for: UIControlState())
        checkboxButton.setImage(UIImage(named: "square_check_box_selected"), for: UIControlState.selected)
        checkboxButton.setTitle(" " + String.localize("LB_CA_TNC_CHECK"), for: UIControlState())
        checkboxButton.setTitleColor(UIColor.secondary2(), for: UIControlState())
        checkboxButton.titleLabel?.formatSize(14)
        checkboxButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
        self.addSubview(checkboxButton)
        
        //Create link button
        linkButton.setTitle(String.localize("LB_CA_TNC_LINK"), for: UIControlState())
        linkButton.titleLabel?.formatSize(14)
        linkButton.setTitleColor(UIColor.primary1(), for: UIControlState())
        self.addSubview(linkButton)
        
        //Create register button
        registerButton.layer.cornerRadius = 2
        registerButton.layer.borderColor = UIColor.primary1().cgColor
        registerButton.layer.borderWidth = 1
        registerButton.titleLabel?.formatSize(14)
        registerButton.setTitleColor(UIColor.primary1(), for: UIControlState())
        registerButton.setTitle(String.localize("LB_CA_REGISTER"), for: UIControlState())
        self.addSubview(registerButton)
        let dismissGesture = UITapGestureRecognizer(target: self, action: #selector(UIInputViewController.dismissKeyboard))
        self.addGestureRecognizer(dismissGesture)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        inputView1.frame = CGRect(x: InputViewMarginLeft, y: 53, width: self.bounds.width - InputViewMarginLeft * 2, height: 95)
        inputBackground.frame = inputView1.bounds
        usernameLabel.frame = CGRect(x: 0, y: 0, width: ShortLabelWith, height: LabelHeight)
        usernameTextField.frame = CGRect(x: ShortLabelWith + TextFieldMarginLeft, y: 0, width: inputView1.bounds.width - (ShortLabelWith + TextFieldMarginLeft + ViewAvatarWidth), height: LabelHeight)
        displaynameLabel.frame = CGRect(x: 0, y: usernameLabel.bounds.maxY, width: ShortLabelWith, height: LabelHeight)
        displaynameTextField.frame = CGRect(x: ShortLabelWith + TextFieldMarginLeft, y: usernameTextField.bounds.maxY, width: inputView1.bounds.width - (ShortLabelWith + TextFieldMarginLeft + ViewAvatarWidth), height: LabelHeight)
        avatarView.frame = CGRect(x: inputView1.bounds.maxX - ViewAvatarWidth, y: 0, width: ViewAvatarWidth, height: ViewAvatarWidth)
        avatarImageView.frame = CGRect(x: (ViewAvatarWidth - ImageAvatarWidth) / 2, y: 15, width: ImageAvatarWidth, height: ImageAvatarWidth)
        profileLabel.frame = CGRect(x: 0, y: avatarImageView.frame.origin.y + avatarImageView.bounds.height + 10, width: avatarView.bounds.maxX, height: 15)
        inputView2.frame = CGRect(x: InputViewMarginLeft, y: inputView1.frame.maxY + 35, width: self.bounds.width - InputViewMarginLeft * 2, height: 95)
        imagePassword.frame = CGRect(x: 0, y: 0, width: self.bounds.maxX - InputViewMarginLeft * 2, height: InputBoxHeight)
        imagePasswordConfirm.frame = CGRect(x: 0, y: imagePassword.frame.maxY - 1, width: self.bounds.maxX - InputViewMarginLeft * 2, height: InputBoxHeight)
        passwordTextField.frame = CGRect(x: 0 , y: 0, width: inputView2.bounds.width, height: LabelHeight)
        passwordConfirmTextField.frame = CGRect(x: 0 , y: imagePasswordConfirm.frame.minY - 1, width: inputView2.bounds.width, height: LabelHeight)
        checkboxButton.frame = CGRect(x: InputViewMarginLeft, y: inputView2.frame.maxY + 15, width: self.bounds.maxX - InputViewMarginLeft * 2, height: 40)
        let width = StringHelper.getTextWidth((linkButton.titleLabel?.text)!, height: 40, font: (linkButton.titleLabel?.font)!)
        let checkboxWidth = StringHelper.getTextWidth((checkboxButton.titleLabel?.text)!, height: 40, font: (checkboxButton.titleLabel?.font)!)
        linkButton.frame = CGRect(x: InputViewMarginLeft + imageCheckbox.size.width + checkboxWidth + 2 , y: checkboxButton.frame.minY, width: width, height: 40)
        registerButton.frame = CGRect(x: InputViewMarginLeft, y: linkButton.frame.maxY + 15, width: self.bounds.maxX - InputViewMarginLeft * 2, height: 42)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    
    func setProfileImage(_ key : String){
     
        avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(key, category: .user), placeholderImage : UIImage(named: Constants.ImageName.ProfileImagePlaceholder), contentMode: .scaleAspectFit)

    }

    func enableRegisterButton(_ isEnable: Bool, isDisableTouch: Bool = true) {
        let backgroundColor = isEnable ? UIColor.primary1() : UIColor.white
        let titleColor = isEnable ? UIColor.white : UIColor.primary1()
        
        registerButton.backgroundColor = backgroundColor
        registerButton.setTitleColor(titleColor, for: UIControlState())
        if isDisableTouch {
            registerButton.isEnabled = isEnable
        }
    }
    
    func isValidData() -> Bool{
        if usernameTextField.text?.length < 1 {
            return false
        } else if usernameTextField.text?.length > 0 {
            if usernameTextField.text?.length < Constants.LenUserName.MinLen
                || usernameTextField.text?.length > Constants.LenUserName.MaxLen{
                return false
            }
            
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Username, text: usernameTextField.text).isEmpty {
                return false
            }
        }
        if displaynameTextField.text?.length < 1 {
            return false
        }
        if passwordTextField.text?.length < 1 {
            return false
        } else {
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Password, text: passwordTextField.text).isEmpty {
                return false
            }
        }
        if passwordConfirmTextField.text?.length < 1 {
            return false
        }
        if passwordConfirmTextField.text != passwordTextField.text {
            return false
        }
//        if !checkboxButton.isSelected{
//            return false
//        }
        return true
    }
}
