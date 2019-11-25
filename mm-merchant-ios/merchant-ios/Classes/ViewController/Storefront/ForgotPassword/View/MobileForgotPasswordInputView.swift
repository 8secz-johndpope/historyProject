//
//  MobileForgotPasswordInputView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 24/2/2016.
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


enum MobileForgotPasswordTextfieldTag: Int{
    case pinCodeTextFieldTag = 1003
    case passwordTextFieldTag = 1004
    case passwordConfirmTextField = 1005
}

class MobileForgotPasswordInputView : UIView,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    var scrollView = UIScrollView()
    var accountLabel = UILabel()
    var descriptionLabel = UILabel()
    var signupInputView : SignupInputView!
    var viewPinCode = UIView()
    
    var passwordTextField = UITextField()
    var passwordConfirmTextField = UITextField()
    var submitButton = UIButton()
    
    private final let ShortLabelWidth : CGFloat = 75
    private final let LabelHeight : CGFloat = 46
    private final let InputViewMarginLeft : CGFloat = 11
    private final let MarginTop : CGFloat = 24
    private final let Spacing : CGFloat = 10
    
    var collectionViewPassword: UICollectionView!
    var collectionViewPasswordHeight: CGFloat = 25
    private let passwordValidationData = NewMobileSignupProfileView.getPasswordValidData()
    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
       
        descriptionLabel.text = String.localize("LB_CA_RESET_PW_DESC")
        descriptionLabel.textAlignment = .center
        descriptionLabel.formatSize(14)
        scrollView.addSubview(descriptionLabel)
        
        signupInputView = SignupInputView(frame: CGRect(x: InputViewMarginLeft, y: 75, width: bounds.width - InputViewMarginLeft * 2, height: 140))
//        signupInputView.activeCodeTextField.format()
        signupInputView.activeCodeTextField.tag = MobileForgotPasswordTextfieldTag.pinCodeTextFieldTag.rawValue
        scrollView.addSubview(signupInputView!)
        
//        swipeSMSView = SwipeSMSView(frame: CGRect(x: InputViewMarginLeft, y: signupInputView.frame.maxY + 20, width: frame.width - InputViewMarginLeft * 2, height: 45))
//        
//        scrollView.addSubview(swipeSMSView!)
        
//        pinCodeTextField.format()
//        pinCodeTextField.tag = MobileForgotPasswordTextfieldTag.PinCodeTextFieldTag.rawValue
//        pinCodeTextField.placeholder = String.localize("LB_CA_INPUT_VERCODE")
//        pinCodeTextField.keyboardType = .NumberPad
//        pinCodeTextField.returnKeyType = UIReturnKeyType.Done;
//        viewPinCode.addSubview(pinCodeTextField)
        
        //Create password
        passwordTextField.format()
        passwordTextField.textAlignment = .left
        passwordTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        passwordTextField.isSecureTextEntry = true
        passwordTextField.tag = MobileForgotPasswordTextfieldTag.passwordTextFieldTag.rawValue
        passwordTextField.placeholder = String.localize("LB_ENTER_PW")
        viewPinCode.addSubview(passwordTextField)
        
        let layout: LeftAlignedCollectionViewFlowLayout = LeftAlignedCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionViewPassword = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionViewPassword.backgroundColor = UIColor.white
        collectionViewPassword.isHidden = false
        collectionViewPassword.delegate = self
        collectionViewPassword.dataSource = self
        collectionViewPassword.tag = 1
        collectionViewPassword.isHidden = true
        collectionViewPassword.register(ValidationViewCell.self, forCellWithReuseIdentifier: ValidationViewCell.CellIdentifier)
        viewPinCode.addSubview(collectionViewPassword)
        
        //Create password confirm
        passwordConfirmTextField.textAlignment = .left
        passwordConfirmTextField.format()
        passwordConfirmTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        passwordConfirmTextField.isSecureTextEntry = true
        passwordConfirmTextField.placeholder = String.localize("LB_CA_CONF_PW")
        passwordConfirmTextField.tag = MobileForgotPasswordTextfieldTag.passwordConfirmTextField.rawValue
        passwordConfirmTextField.returnKeyType = UIReturnKeyType.done;
        viewPinCode.addSubview(passwordConfirmTextField)
        
        //Create submit button
        submitButton.formatPrimary()
        submitButton.setTitle(String.localize("LB_CA_SUBMIT"), for: UIControlState())
        self.viewPinCode.addSubview(submitButton)
        scrollView.addSubview(viewPinCode)
        self.addSubview(scrollView)
        
       
        self.collectionViewPasswordHeight = self.getCollectionViewHeight()
        
        self.layout()
        scrollView.contentSize = CGSize(width: frame.width,height: viewPinCode.frame.maxY)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layout()
    }
    
    func layout(){
        descriptionLabel.frame = CGRect(x: InputViewMarginLeft, y: MarginTop, width: bounds.width - InputViewMarginLeft * 2, height: LabelHeight)
        viewPinCode.frame = CGRect(x: 0, y: signupInputView.frame.maxY + 20, width:frame.width, height: 250)
//        pinCodeTextField.frame = CGRect(x: InputViewMarginLeft, y: 0, width:frame.width - InputViewMarginLeft * 2, height: LabelHeight )
        passwordTextField.frame = CGRect(x: InputViewMarginLeft , y: 0, width: bounds.width - InputViewMarginLeft * 2, height: LabelHeight)
        
        collectionViewPassword.frame = CGRect(x: InputViewMarginLeft , y: passwordTextField.frame.maxY + 20, width: bounds.width - InputViewMarginLeft * 2, height: self.collectionViewPasswordHeight)
        
        self.layoutForDynamicViews()
    }
    
    func layoutForDynamicViews(){
        var postY = collectionViewPassword.frame.maxY + 10
        if collectionViewPassword.isHidden {
            postY = passwordTextField.frame.maxY
        }
        
        passwordConfirmTextField.frame = CGRect(x: InputViewMarginLeft , y: postY - 1, width: bounds.width - InputViewMarginLeft * 2, height: LabelHeight)
        
        submitButton.frame = CGRect(x: InputViewMarginLeft, y: passwordConfirmTextField.frame.maxY + 15, width: self.bounds.maxX - InputViewMarginLeft * 2, height: 42)
        viewPinCode.height = submitButton.frame.maxY + 5
        scrollView.contentSize = CGSize(width: frame.width,height: viewPinCode.frame.maxY)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return passwordValidationData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ValidationViewCell.CellIdentifier, for: indexPath) as! ValidationViewCell
        cell.upperLabel.text = passwordValidationData[indexPath.row].text
        cell.setValid(passwordValidationData[indexPath.row].isValid)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        let width : CGFloat = ceil(ValidationViewCell.ImageWidth + ValidationViewCell.Spacing + StringHelper.getTextWidth(passwordValidationData[indexPath.row].text, height: Constants.Value.ValidationCellHeight, font: UIFont.systemFont(ofSize: CGFloat(ValidationViewCell.FontSize))))
        return CGSize(width: width, height: Constants.Value.ValidationCellHeight)
    }

    func getCollectionViewHeight() ->CGFloat {
        var width: CGFloat = 0
        for i in 0..<passwordValidationData.count {
            width += self.collectionView(self.collectionViewPassword, layout: self.collectionViewPassword.collectionViewLayout, sizeForItemAt: IndexPath(row: i, section: 0)).width
        }
        width += (InputViewMarginLeft * 2 + CGFloat((passwordValidationData.count - 1)) * Spacing)
        if width > self.bounds.width {
            return Constants.Value.ValidationCellHeight * 2
        }
        return Constants.Value.ValidationCellHeight
    }
    
    func textFieldDidBeginEditing(_ tag: Int) {
        if tag == self.passwordTextField.tag {
            
            if (self.getPasswordError() == nil){
                self.collectionViewPassword.isHidden = true
            } else {
                self.collectionViewPassword.isHidden = false
                self.collectionViewPassword.reloadData()
            }
            self.passwordTextField.shouldHighlight(false)
        }
        self.layoutForDynamicViews()
    }
    
    func didChangeCharacters(_ textField : UITextField) {
        let isPasswordValid = self.getPasswordError() == nil
        
        if textField.tag == passwordTextField.tag {
            if isPasswordValid  {
                self.passwordTextField.shouldHighlight(false)
                self.collectionViewPassword.isHidden = true
            } else {
                self.collectionViewPassword.isHidden = false
                self.collectionViewPassword.reloadData()
            }
            if textField.text?.length > 0 && textField.text == self.passwordConfirmTextField.text{
                self.passwordConfirmTextField.shouldHighlight(false)
            }
        }
        self.layoutForDynamicViews()
    }
    

    func getPasswordError() -> String?{
        var errorMessage : String?
        if let text : String = passwordTextField.text, text.length > 0{
            let error = String.localize("MSG_ERR_CA_PW_PATTERN")
//            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.PasswordSpecialCharactor, text: text).isEmpty {
//                passwordValidationData[3].isValid = false
//                errorMessage = error
//            } else {
//                passwordValidationData[3].isValid = true
//            }
            
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.PasswordDigit, text: text).isEmpty {
                passwordValidationData[2].isValid = false
                errorMessage = error
            } else {
                passwordValidationData[2].isValid = true
            }
            
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.PasswordCharacter, text: text).isEmpty {
                passwordValidationData[1].isValid = false
                errorMessage = error
            } else {
                passwordValidationData[1].isValid = true
            }
            
            if text.length < Constants.Value.PasswordMinLength || text.length > Constants.Value.PasswordMaxLength {
                passwordValidationData[0].isValid = false
                errorMessage = error
                
            } else {
                passwordValidationData[0].isValid = true
            }
        } else {
            
            errorMessage = String.localize("MSG_ERR_CA_PW_NIL")
            
            passwordValidationData[0].isValid = false
            passwordValidationData[1].isValid = false
            passwordValidationData[2].isValid = false
            //passwordValidationData[3].isValid = false
        }
        
        return errorMessage
    }
}
