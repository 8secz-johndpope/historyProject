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
private func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}



class NewMobileSignupProfileView: UIView ,UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    private final let InputViewMarginLeft : CGFloat = 20
    private final let ButtonRegisterHeight : CGFloat = 42
    private final let LabelProfileHeight : CGFloat = 30
    private final let MarginTop : CGFloat = 50
    final let MarginBottom : CGFloat = 10
    private final let TextFieldMarginLeft : CGFloat = 10
    private final let Spacing : CGFloat = 10
    final let InputBoxHeight : CGFloat = 36
    private final let ImageAvatarWidth : CGFloat = 60
    var scrollView = UIScrollView()
    private var avatarView = UIView()
//    private var borderView = UIView()
//    private var borderViewPassword = UIView()
    var avatarImageView = UIImageView()
    private var profileLabel = UILabel()
    var displayNameBackground = UIImageView()
    var displayNameTextField = UITextField()
    var passwordBackground = UIImageView()
    var passwordTextField = UITextField()
    var registerButton = UIButton()
    var collectionView: UICollectionView!
    var collectionViewPassword: UICollectionView!
    var collectionViewHeight: CGFloat = 25
    var collectionViewPasswordHeight: CGFloat = 25
    var duration = TimeInterval(0.0)
    //var data : [ValidationData] = []
   private let displayNameValidationData = [ValidationData(text: String.localize("MSG_ERR_CA_NICKNAME_NIL"))]
    
    private let passwordValidationData = NewMobileSignupProfileView.getPasswordValidData()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        scrollView.backgroundColor = UIColor.white
        scrollView.frame = self.bounds
        scrollView.contentSize = self.bounds.size
        //Create avatar view
        avatarView.backgroundColor = UIColor.clear
        avatarImageView.image = UIImage(named: "default_profile_icon")
        avatarImageView.isUserInteractionEnabled = true;
        avatarImageView.round()
        avatarView.addSubview(avatarImageView)
        scrollView.addSubview(avatarView)
        
        profileLabel.textAlignment = .center
        profileLabel.formatSize(12)
        profileLabel.text = String.localize("LB_CA_PROFILE_PIC")
        avatarView.addSubview(profileLabel)
        
        let inputBoxSingle = UIImage(named: "input_box_single")
        inputBoxSingle?.resizableImage(withCapInsets: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        displayNameBackground.image = inputBoxSingle
        displayNameBackground.isUserInteractionEnabled = true
        displayNameTextField.textAlignment = .left
        displayNameTextField.textColor = UIColor.secondary2()
        displayNameTextField.font = UIFont.systemFont(ofSize: 14)
        displayNameTextField.tag = 0
        displayNameTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        displayNameTextField.autocapitalizationType = .none
        displayNameTextField.autocorrectionType = .no
        displayNameTextField.placeholder = String.localize("LB_CA_NICKNAME_LIMITED")
        displayNameBackground.addSubview(displayNameTextField)
        scrollView.addSubview(displayNameBackground)

        

        //Create password
        passwordTextField.textAlignment = .left
        passwordTextField.textColor = UIColor.secondary2()
        passwordTextField.font = UIFont.systemFont(ofSize: 14)
        passwordTextField.clearButtonMode = UITextFieldViewMode.whileEditing
        passwordTextField.isSecureTextEntry = true
        passwordTextField.tag = 1
        passwordTextField.placeholder = String.localize("LB_ENTER_PW")
        passwordBackground.image = inputBoxSingle
        passwordBackground.addSubview(passwordTextField)
        passwordBackground.isUserInteractionEnabled = true
        scrollView.addSubview(passwordBackground)
        
        //Create register button
        registerButton.formatDisable()
        registerButton.setTitle(String.localize("LB_CA_REGISTER"), for: UIControlState())
        scrollView.addSubview(registerButton)
        
        let layout: LeftAlignedCollectionViewFlowLayout = LeftAlignedCollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.isHidden = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isHidden = true
        collectionView.tag = 0
        collectionView.register(ValidationViewCell.self, forCellWithReuseIdentifier: ValidationViewCell.CellIdentifier)
        scrollView.addSubview(collectionView)
        
        
        let layout2: LeftAlignedCollectionViewFlowLayout = LeftAlignedCollectionViewFlowLayout()
        layout2.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionViewPassword = UICollectionView(frame: bounds, collectionViewLayout: layout2)
        collectionViewPassword.backgroundColor = UIColor.white
        collectionViewPassword.isHidden = false
        collectionViewPassword.delegate = self
        collectionViewPassword.dataSource = self
        collectionViewPassword.tag = 1
        collectionViewPassword.isHidden = true
        collectionViewPassword.register(ValidationViewCell.self, forCellWithReuseIdentifier: ValidationViewCell.CellIdentifier)
        scrollView.addSubview(collectionViewPassword)
        
        displayNameBackground.layer.borderColor = UIColor.primary1().cgColor
        passwordBackground.layer.borderColor = UIColor.primary1().cgColor
        
//        borderView.backgroundColor = UIColor.clear
//        borderView.layer.borderColor = UIColor.primary1().cgColor
//        borderView.layer.borderWidth = 1
//        borderView.isUserInteractionEnabled = false
        
        
        self.addSubview(scrollView)
        collectionViewHeight = self.getCollectionViewHeight(collectionView.tag)
//        collectionViewPasswordHeight = self.getCollectionViewHeight(collectionViewPassword.tag)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
       
        avatarView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: MarginTop + ImageAvatarWidth + LabelProfileHeight)
        avatarImageView.frame = CGRect(x: (avatarView.frame.width - ImageAvatarWidth) / 2, y: MarginTop, width: ImageAvatarWidth, height: ImageAvatarWidth)
        profileLabel.frame = CGRect(x: 0, y: avatarImageView.frame.maxY, width: avatarView.bounds.width, height: LabelProfileHeight)
        self.layoutForDynamicViews()
    }
    func layoutForDynamicViews(){
        let width = self.bounds.width - InputViewMarginLeft * 2
        displayNameBackground.frame = CGRect(x: InputViewMarginLeft, y: avatarView.frame.maxY + MarginBottom, width: width, height: InputBoxHeight)
        displayNameTextField.frame = CGRect(x: TextFieldMarginLeft, y: 0, width: displayNameBackground.bounds.width - (TextFieldMarginLeft * 2), height: InputBoxHeight)
        
        self.collectionView.frame = CGRect(x: self.InputViewMarginLeft, y: self.displayNameBackground.frame.maxY, width: width, height: self.collectionViewHeight)
        
        var postY = collectionView.frame.maxY + MarginBottom
        if collectionView.isHidden {
            postY = displayNameBackground.frame.maxY + MarginBottom
        }
        
        passwordBackground.frame = CGRect(x: InputViewMarginLeft, y: postY, width: width, height: InputBoxHeight)
        passwordTextField.frame =  CGRect(x: TextFieldMarginLeft, y: 0, width: passwordBackground.frame.width - TextFieldMarginLeft * 2, height: InputBoxHeight)
        
        collectionViewPassword.frame = CGRect(x: InputViewMarginLeft, y: passwordBackground.frame.maxY, width: width, height: collectionViewPasswordHeight)
        
        postY = collectionViewPassword.frame.maxY + MarginBottom
        if collectionViewPassword.isHidden {
            postY = passwordBackground.frame.maxY + MarginBottom
        }
        registerButton.frame = CGRect(x: InputViewMarginLeft, y: postY, width: self.bounds.maxX - InputViewMarginLeft * 2, height: ButtonRegisterHeight)
     
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
   
    
    func setProfileImage(_ key : String){
        avatarImageView.mm_setImageWithURL(ImageURLFactory.URLSize256(key, category: .user), placeholderImage : UIImage(named: Constants.ImageName.ProfileImagePlaceholder), contentMode: .scaleAspectFit)
    }

    func enableRegisterButton(_ isEnable: Bool, isDisableTouch: Bool = true) {
        if isEnable {
             registerButton.formatPrimary()
        } else {
             registerButton.formatDisable()
        }
       
        if isDisableTouch {
            registerButton.isEnabled = isEnable
        }
        registerButton.layer.cornerRadius = CGFloat(2)
        
    }
    
    func isValidData() -> Bool{
        return true
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView.tag == 0 {
            return displayNameValidationData.count
        }
        return passwordValidationData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var data : [ValidationData] = displayNameValidationData
        if collectionView.tag == 1{
            data = passwordValidationData
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ValidationViewCell.CellIdentifier, for: indexPath) as! ValidationViewCell
        cell.upperLabel.text = data[indexPath.row].text
        cell.setValid(data[indexPath.row].isValid)
        //cell.backgroundColor = UIColor.lightGray
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return Spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var data : [ValidationData] = displayNameValidationData
        if collectionView.tag == 1 {
            data = passwordValidationData
        }
        
        let width : CGFloat = ceil(ValidationViewCell.ImageWidth + ValidationViewCell.Spacing + StringHelper.getTextWidth(data[indexPath.row].text, height: Constants.Value.ValidationCellHeight, font: UIFont.systemFont(ofSize: CGFloat(ValidationViewCell.FontSize))))
        return CGSize(width: width, height: Constants.Value.ValidationCellHeight)
    }
    
    /*
    func getUsernameError() -> String?{
        var errorMessage : String?
        if let text = usernameTextField.text, text.length > 0 {
            let error = String.localize("MSG_ERR_CA_USERNAME_PATTERN")
            if !RegexManager.matchesForRegexInText(RegexManager.ValidPattern.UsernameSpecialCharactor, text: text).isEmpty {
                usernameValidationData[3].isValid = false
                errorMessage = error
            } else {
                usernameValidationData[3].isValid = true
            }
            if text.contains(" ") {
                usernameValidationData[2].isValid = false
                errorMessage = error
            } else {
                usernameValidationData[2].isValid = true
            }
            
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Username, text: text.trim()).isEmpty {
                usernameValidationData[1].isValid = false
                errorMessage = error
            } else {
                usernameValidationData[1].isValid = true
            }
            
            if text.length < 6 || text.length > 17 {
                errorMessage = error
                usernameValidationData[0].isValid = false
            } else {
                usernameValidationData[0].isValid = true
            }
    
        } else {
            errorMessage = String.localize("MSG_ERR_CA_USERNAME_NIL")
            usernameValidationData[0].isValid = false
            usernameValidationData[1].isValid = false
            usernameValidationData[2].isValid = false
            usernameValidationData[3].isValid = false
        }
        
        return errorMessage
    }*/
    
    func getDisplayNameError() -> String?{
        //
        var errorMessage : String?
        if displayNameTextField.text == nil || displayNameTextField.text?.length <= 0 {
            errorMessage = String.localize("MSG_ERR_CA_NICKNAME_NIL")
            displayNameValidationData[0].isValid = false
            return errorMessage
        }
        return nil
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
    
    func getErrorMessage() -> String? {
        if let errorMessage = self.getDisplayNameError(){
            return errorMessage
        }
        
        if let errorMessage = self.getPasswordError(){
            return errorMessage
        }
        return nil
    }
    
    func showAnimation(_ collection: UICollectionView) {
        
        if collection.alpha >= 1 && !collection.isHidden {
            return
        }
        
        collection.isHidden = false
        collection.alpha = 0
        UIView.animate(withDuration: 0.5, animations: { 
            collection.alpha = 1
            }, completion: { (success) in
                
                
        }) 
    }
    
    func textFieldDidBeginEditing(_ tag: Int) {
        if tag == self.displayNameTextField.tag {
            if (getDisplayNameError() == nil) {
                self.collectionView.isHidden = true
            } else {
                if self.collectionView.isHidden == true {
                    self.collectionView.alpha = 0
                }else {
                    self.collectionView.alpha = 1
                }
                self.collectionView.isHidden = false
                self.collectionView.reloadData()
                
            }
            showBorder(false, isDisplayName: true)
        } else {
           
            if (self.getPasswordError() == nil){
                self.collectionViewPassword.isHidden = true
            } else {
                if self.collectionViewPassword.isHidden == true {
                    self.collectionViewPassword.alpha = 0
                }else {
                    self.collectionViewPassword.alpha = 1
                }

                self.collectionViewPassword.isHidden = false
                self.collectionViewPassword.reloadData()
            }
            showBorder(false, isDisplayName: false)
        }
        self.layoutForDynamicViews()
    }
    
    func didChangeCharacters(_ textField : UITextField) {
        let isDisplayNameValid = self.getDisplayNameError() == nil
        let isPasswordValid = self.getPasswordError() == nil

        if textField.tag == displayNameTextField.tag {
            if isDisplayNameValid {
                self.showBorder(false, isDisplayName: true)
                self.collectionView.isHidden = true
            } else {
//                self.collectionView.isHidden = false
                self.showAnimation(self.collectionView)
                self.collectionView.reloadData()
            }
        } else {
           
            
            if isPasswordValid  {
                self.showBorder(false, isDisplayName: false)
                self.collectionViewPassword.isHidden = true
            } else {
//                self.collectionViewPassword.isHidden = false
                self.collectionViewPassword.reloadData()
                self.showAnimation(self.collectionViewPassword)

            }
            
        }
       
        self.enableRegisterButton((isPasswordValid && isDisplayNameValid), isDisableTouch: false)
        self.layoutForDynamicViews()
    }
    
    func showBorder(_ isShow: Bool, isDisplayName: Bool = true){
        var borderWidth: CGFloat = 0
        if isShow {
            borderWidth = 1
        }
        if isDisplayName {
            self.displayNameBackground.layer.borderWidth = borderWidth
        } else {
            
            self.passwordBackground.layer.borderWidth = borderWidth
        }
    }
    
    func getCollectionViewHeight(_ tag: Int) ->CGFloat {
        var width: CGFloat = 0
        var data : [ValidationData] = displayNameValidationData
        if tag == 1 {
            data = passwordValidationData
        }
        for i in 0..<data.count {
            width += self.collectionView(self.collectionView, layout: self.collectionView.collectionViewLayout, sizeForItemAt: IndexPath(row: i, section: 0)).width
        }
        width += (InputViewMarginLeft * 2 + CGFloat((data.count - 1)) * Spacing)
        if width > self.bounds.width {
            return  Constants.Value.ValidationCellHeight * 2
        }
        return Constants.Value.ValidationCellHeight
    }
    
    class func getPasswordValidData() ->[ValidationData]{
        return [ValidationData(text:String.localize("LB_CA_PASSWORD_LENGTH")),ValidationData(text:String.localize("LB_CA_PASSWORD_LETTER")),ValidationData(text:String.localize("LB_CA_PASSWORD_DIGIT")),]
    }
}

class ValidationData{
    convenience init(text: String) {
        self.init()
        self.text = text
    }
    var text : String = ""
    var isValid: Bool = false
}


class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let attributes = super.layoutAttributesForElements(in: rect)
        
        var leftMargin = sectionInset.left
        var maxY: CGFloat = -1.0
        attributes?.forEach { layoutAttribute in
            if layoutAttribute.frame.origin.y >= maxY {
                leftMargin = sectionInset.left
            }
            
            layoutAttribute.frame.origin.x = leftMargin
            
            leftMargin += layoutAttribute.frame.width + minimumInteritemSpacing
            maxY = max(layoutAttribute.frame.maxY , maxY)
        }
        
        return attributes
    }
    
}
