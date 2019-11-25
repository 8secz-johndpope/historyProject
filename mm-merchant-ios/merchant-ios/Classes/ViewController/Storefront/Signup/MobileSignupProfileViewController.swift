//
//  MobileSignupProfileViewController.swift
//  merchant-ios
//
//  Created by Sang on 2/2/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Alamofire
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


// MARK: Deprecated
@available(*, deprecated, message: "no longer used, please use NewMobileSignupProfileViewController")
class MobileSignupProfileViewController: SignupModeViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, ImagePickerManagerDelegate {
    
    enum TextFieldTag : Int {
        case userName = 1,
        displayName,
        password,
        confirmPassword
    }
    
    private var mobileSignupProfileView: MobileSignupProfileView!
    
    var picker = UIImagePickerController()
    var profileImage = UIImage()
    
    var mobileNumber = ""
    var mobileCode = ""
    var mobileVerificationId = 0
    var mobileVerficationToken = ""
    
    private var imagePickerManager: ImagePickerManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_REGISTER")
        
        mobileSignupProfileView = MobileSignupProfileView(frame: CGRect(x: 0, y: 65, width: view.width, height: 400))
        mobileSignupProfileView.linkButton.isHidden = true
        mobileSignupProfileView.checkboxButton.isHidden = true
        mobileSignupProfileView.registerButton.addTarget(self, action: #selector(MobileSignupProfileViewController.registerClicked), for: .touchUpInside)
        mobileSignupProfileView.registerButton.isEnabled = true
        mobileSignupProfileView.usernameTextField.keyboardType = .asciiCapable
        mobileSignupProfileView.usernameTextField.delegate = self
        mobileSignupProfileView.displaynameTextField.delegate = self
        mobileSignupProfileView.passwordConfirmTextField.delegate = self
        mobileSignupProfileView.passwordTextField.delegate = self
        
        var gesture = UITapGestureRecognizer(target: self, action: #selector(MobileSignupProfileViewController.changeProfileImage))
        mobileSignupProfileView.avatarImageView.addGestureRecognizer(gesture)
        view.addSubview(mobileSignupProfileView)
        
        picker.delegate = self
        
        gesture = UITapGestureRecognizer(target: self, action: #selector(MobileSignupProfileViewController.dissmissKeyboard))
        view.addGestureRecognizer(gesture)
        mobileSignupProfileView.addGestureRecognizer(gesture)
        
        createRightCancelButton(#selector(MobileSignupProfileViewController.rightBarButtonClicked))
        
        initAnalyticsViewRecord(
            viewLocation: "MobileSignupInfo",
            viewType: "Signup"
        )
        
        
        mobileSignupProfileView.passwordTextField.addTarget(self, action: #selector(MobileSignupProfileViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
        
        mobileSignupProfileView.passwordConfirmTextField.addTarget(self, action: #selector(MobileSignupProfileViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Hide Back Button
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItem = nil
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mobileSignupProfileView.passwordTextField.isSecureTextEntry = false
        mobileSignupProfileView.passwordTextField.isSecureTextEntry = true
        mobileSignupProfileView.passwordConfirmTextField.isSecureTextEntry = false
        mobileSignupProfileView.passwordConfirmTextField.isSecureTextEntry = true
    }
   
    // MARK: - Action
    
    @objc func registerClicked(_ sender : UIButton) {
        self.dissmissKeyboard()
        Log.debug("registerClicked")
        if !self.isValidData(true) {
            return
        }
        firstly{
            return self.signup()
        }.then { _ in
//            self.view.endEditing(true)
            return self.uploadProfileImage(self.getCropImage(self.profileImage))
        }.then { _ -> Void in
            
            if self.signupMode == .checkout || self.signupMode == .checkoutSwipeToPay {
                let viewController: UIViewController
                // handle the sign up mode form check out
                viewController = AddressAdditionViewController()
                (viewController as! AddressAdditionViewController).signupMode =  self.signupMode
                 self.navigationController?.pushViewController(viewController, animated: true)
            } else {
                LoginManager.goToStorefront()
            }
        }.catch { (error) in
            let err = error as NSError
            self.showError(err.localizedDescription, animated: true)
        }
    }
    
    @objc func rightBarButtonClicked() {
        Alert.alert(self, title: "", message: String.localize("LB_CA_SIGNUP_CANCEL"), okActionComplete: { () -> Void in
            if let controllers = self.navigationController?.viewControllers {
                for controller in controllers {
                    if controller is InvitationCodeSuccessfulViewController {
                        self.navigationController?.popToViewController(controller, animated: true)
                        return
                    }
                }
            }
            self.navigationController?.popViewController(animated: true)
        }, cancelActionComplete:nil)
    }
    
    @objc func changeProfileImage() {
        if imagePickerManager == nil {
            imagePickerManager = ImagePickerManager(viewController: self, withDelegate: self)
        }
        
        imagePickerManager!.presentDefaultActionSheet(preferredCameraDevice: .front)
    }
    
    func signup()-> Promise<Void> {
        
        let param = AuthService.SignUpParameter(mobileNumber: self.mobileNumber, mobileCode: self.mobileCode, mobileVerificationId: self.mobileVerificationId, mobileVerificationToken: self.mobileVerficationToken, password: self.mobileSignupProfileView.passwordConfirmTextField.text  ?? "", displayName: self.mobileSignupProfileView.displaynameTextField.text ?? "", inviteCode: Context.getInvitationCode())
        
        return LoginManager.signup(param)
        
    }
    
    func uploadProfileImage(_ image: UIImage) {
        if image.size.width > 0 {
            UserService.uploadImage(image, imageType: .profile, success: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            
                            
                            if let imageUploadResponse = Mapper<ImageUploadResponse>().map(JSONObject: response.result.value) {
                                strongSelf.mobileSignupProfileView.setProfileImage(imageUploadResponse.profileImage)
                            }
                        }
                    }
                    
                    Log.debug("error")
                    strongSelf.stopLoading()
                }
            }, fail: { [weak self] encodingError in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                    self!.showSuccessPopupWithText(String.localize("error"))
                }
            })
        }
    }
    
    func enableRegisterButton(_ isEnable: Bool) {
        mobileSignupProfileView.enableRegisterButton(isEnable, isDisableTouch: false)
    }
    
    @objc func dissmissKeyboard() {
        self.view.endEditing(true)
    }
    
    //MARK: UITextFieldDelegate
    
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if textField == mobileSignupProfileView.passwordTextField || textField == mobileSignupProfileView.passwordConfirmTextField {
            
            textField.setStyleDefault()
        }
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        var isValid = true
        
        if let textFieldTag = TextFieldTag(rawValue: textField.tag){
            switch textFieldTag {
            case .userName:
                if mobileSignupProfileView.usernameTextField.text?.trim().length < 1 {
                    self.showError(String.localize("MSG_ERR_CA_USERNAME_NIL"), animated: true)
                    isValid = false
                }
                
                if mobileSignupProfileView.usernameTextField.text?.trim().length > 0 {
                    if mobileSignupProfileView.usernameTextField.text?.trim().length < Constants.LenUserName.MinLen
                        || mobileSignupProfileView.usernameTextField.text?.trim().length > Constants.LenUserName.MaxLen{
                        
                        self.showError(String.localize("MSG_ERR_CA_USERNAME_PATTERN"), animated: true)
                        isValid = false
                    }
                    
                    if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Username, text: mobileSignupProfileView.usernameTextField.text?.trim()).isEmpty {
                        self.showError(String.localize("MSG_ERR_CA_USERNAME_PATTERN"), animated: true)
                        isValid = false
                    }
                }
                break
            case .displayName:
                if mobileSignupProfileView.displaynameTextField.text?.trim().length < 1 {
                    self.showError(String.localize("MSG_ERR_DISP_NAME_NIL"), animated: true)
                    isValid = false
                }
                break
            case .password, .confirmPassword:
                switch textFieldTag {
                case .password:
                    if mobileSignupProfileView.passwordTextField.text?.length < 1 {
                        self.showError(String.localize("MSG_ERR_CA_PW_NIL"), animated: true)
                        isValid = false
                    }
                    if mobileSignupProfileView.passwordTextField.text?.length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Password, text: mobileSignupProfileView.passwordTextField.text).isEmpty {
                        self.showError(String.localize("MSG_ERR_CA_PW_PATTERN"), animated: true)
                        isValid = false
                    }
                    break
                case .confirmPassword:
                    if mobileSignupProfileView.passwordConfirmTextField.text?.length < 1 {
                        self.showError(String.localize("MSG_ERR_CA_PW_NIL"), animated: true)
                        isValid = false
                    }
                    if mobileSignupProfileView.passwordConfirmTextField.text?.length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Password, text: mobileSignupProfileView.passwordConfirmTextField.text).isEmpty {
                        self.showError(String.localize("MSG_ERR_CA_PW_PATTERN"), animated: true)
                        isValid = false
                    }
                    break
                default:
                    break
                }
                
                if mobileSignupProfileView.passwordConfirmTextField.text?.length > 0
                    && mobileSignupProfileView.passwordTextField.text?.length > 0
                    && mobileSignupProfileView.passwordConfirmTextField.text != mobileSignupProfileView.passwordTextField.text {
                    self.showError(String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"), animated: true)
                    isValid = false
                    
                }
                textField.isSecureTextEntry = false
                textField.isSecureTextEntry = true
                break
            }
        }

        if !isValid {
            self.enableRegisterButton(false)
        } else {
            self.enableRegisterButton(self.isValidData())
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        self.enableRegisterButton(false)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MobileSignupProfileViewController.checkValidData), userInfo: nil, repeats: false)
        return true
    }
    
    @objc func checkValidData() {
        self.enableRegisterButton(self.isValidData())
    }
    
    // MARK: - ImagePickerManagerDelegate
    
    func didPickImage(_ image: UIImage!) {
        profileImage = image
        mobileSignupProfileView.avatarImageView.round()
        mobileSignupProfileView.avatarImageView.image = profileImage
        mobileSignupProfileView.avatarImageView.contentMode = .scaleAspectFill
    }
    
    func getCropImage(_ croppedImage: UIImage) -> UIImage {
        if (croppedImage.size.width > ImageSizeCrop.width_max || croppedImage.size.height > ImageSizeCrop.height_max) {
            if let resizeImage = croppedImage.resize(CGSize(width: ImageSizeCrop.width_max, height: ImageSizeCrop.height_max), contentMode: UIImage.UIImageContentMode.scaleToFill, quality: CGInterpolationQuality.high){
                return resizeImage
            }
            else{
                return croppedImage
            }
            
        } else {
            return croppedImage
        }
        
    }
    
    func styleValidateError(_ isHighlight: Bool, message: String? = nil, textField: UITextField) {
        
        if isHighlight {
            
            
            self.showError(message ?? "", animated: true)
            textField.becomeFirstResponder()
            textField.shouldHighlight(true)
            
            
        } else {
            
            textField.shouldHighlight(false)
        }
    }
    
    func isValidData(_ isShowErrorMessage: Bool = false) -> Bool{
        
        if mobileSignupProfileView.usernameTextField.text?.trim().length < 1 {
            if isShowErrorMessage {
                self.showError(String.localize("MSG_ERR_CA_USERNAME_NIL"), animated: true)
            }
            return false
        }
        if mobileSignupProfileView.usernameTextField.text?.trim().length > 0 {
            if mobileSignupProfileView.usernameTextField.text?.trim().length < Constants.LenUserName.MinLen
                || mobileSignupProfileView.usernameTextField.text?.trim().length > Constants.LenUserName.MaxLen{
                if isShowErrorMessage {
                    self.showError(String.localize("MSG_ERR_CA_USERNAME_PATTERN"), animated: true)
                }
                return false
            }
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Username, text: mobileSignupProfileView.usernameTextField.text?.trim()).isEmpty {
                if isShowErrorMessage {
                    self.showError(String.localize("MSG_ERR_CA_USERNAME_PATTERN"), animated: true)
                }
                return false
            }
        }
        if mobileSignupProfileView.displaynameTextField.text?.trim().length < 1 {
            if isShowErrorMessage {
                self.showError(String.localize("MSG_ERR_DISP_NAME_NIL"), animated: true)
            }
            return false
        }
        if mobileSignupProfileView.passwordTextField.text?.length < 1 {
            if isShowErrorMessage {
//                self.showError(String.localize("MSG_ERR_CA_PW_NIL"), animated: true)
                styleValidateError(true, message: String.localize("MSG_ERR_CA_PW_NIL"), textField: mobileSignupProfileView.passwordTextField)
            }
            return false
        }
        if mobileSignupProfileView.passwordTextField.text?.length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Password, text: mobileSignupProfileView.passwordTextField.text).isEmpty {
            if isShowErrorMessage {
//                self.showError(String.localize("MSG_ERR_CA_PW_PATTERN"), animated: true)
                
                styleValidateError(true, message: String.localize("MSG_ERR_CA_PW_PATTERN"), textField: mobileSignupProfileView.passwordTextField)
            }
            return false
        }
        
        styleValidateError(false, textField: mobileSignupProfileView.passwordTextField)
        
        if mobileSignupProfileView.passwordConfirmTextField.text?.length < 1 {
            if isShowErrorMessage {
//                self.showError(String.localize("MSG_ERR_CA_PW_NIL"), animated: true)
                
                styleValidateError(true, message: String.localize("MSG_ERR_CA_PW_NIL"), textField: mobileSignupProfileView.passwordConfirmTextField)
            }
            return false
        }
        if mobileSignupProfileView.passwordConfirmTextField.text?.length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Password, text: mobileSignupProfileView.passwordConfirmTextField.text).isEmpty {
            if isShowErrorMessage {
//                self.showError(String.localize("MSG_ERR_CA_PW_PATTERN"), animated: true)
                
                styleValidateError(true, message: String.localize("MSG_ERR_CA_PW_PATTERN"), textField: mobileSignupProfileView.passwordConfirmTextField)
            }
            return false
        }
        
        if mobileSignupProfileView.passwordConfirmTextField.text?.length > 0
            && mobileSignupProfileView.passwordTextField.text?.length > 0
            && mobileSignupProfileView.passwordConfirmTextField.text != mobileSignupProfileView.passwordTextField.text {
            if isShowErrorMessage {
                self.showError(String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"), animated: true)
            }
            return false
        }
        
        styleValidateError(false, textField: mobileSignupProfileView.passwordConfirmTextField)
        return true
    }
}
