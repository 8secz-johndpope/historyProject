//
//  NewMobileSignupProfileViewController.swift
//  merchant-ios
//
//  Created by Sang on 10/6/16.
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
private func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


class NewMobileSignupProfileViewController: SignupModeViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, ImagePickerManagerDelegate {
    
    enum TextFieldTag : Int {
        case userName = 1,
        displayName,
        password,
        confirmPassword
    }
    
    private var mobileSignupProfileView: NewMobileSignupProfileView!
    
    var picker = UIImagePickerController()
    var profileImage = UIImage()
    
    var mobileNumber = ""
    var mobileCode = ""
    var mobileVerificationId = 0
    var mobileVerficationToken = ""
    var isEnabal = true
    private var isShowingKeyboard = false
    private var imagePickerManager: ImagePickerManager?
    private var selectedTextField: UITextField?
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_REGISTER")
        let navigationBarHeight = (self.navigationController?.navigationBar.height ?? 0) + 20
        mobileSignupProfileView = NewMobileSignupProfileView(frame: CGRect(x: 0, y: navigationBarHeight, width: view.width, height: self.view.size.height - navigationBarHeight))
        
        mobileSignupProfileView.registerButton.addTarget(self, action: #selector(self.registerClicked), for: .touchUpInside)
        mobileSignupProfileView.registerButton.isEnabled = true
        mobileSignupProfileView.displayNameTextField.delegate = self
        mobileSignupProfileView.passwordTextField.delegate = self
        
        var gesture = UITapGestureRecognizer(target: self, action: #selector(self.changeProfileImage))
        mobileSignupProfileView.avatarImageView.addGestureRecognizer(gesture)
        view.addSubview(mobileSignupProfileView)
        
        picker.delegate = self
        
        gesture = UITapGestureRecognizer(target: self, action: #selector(self.dissmissKeyboard))
        view.addGestureRecognizer(gesture)
        mobileSignupProfileView.addGestureRecognizer(gesture)
        
        createRightCancelButton(#selector(self.rightBarButtonClicked))
        
        initAnalyticsViewRecord(
            viewLocation: "SignupInfo",
            viewType: "Signup"
        )
        
        let dismissGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard))
        mobileSignupProfileView.scrollView.addGestureRecognizer(dismissGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isEnabal = true
        //Hide Back Button
        self.navigationItem.setHidesBackButton(true, animated: false)
        self.navigationItem.leftBarButtonItem = nil
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//          NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDidShow(_:)), name: UIKeyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isEnabal = false
        self.view.endEditing(true)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        mobileSignupProfileView.passwordTextField.isSecureTextEntry = false
        mobileSignupProfileView.passwordTextField.isSecureTextEntry = true
    }
    
    // MARK: - Action
    
    @objc func registerClicked(_ sender : UIButton) {
        
        sender.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        sender.recordAction(.Tap, sourceRef: "Signup", sourceType: .Button, targetRef: "Signup", targetType: .Submit)
        
        self.dissmissKeyboard()
        Log.debug("registerClicked")
        if !self.isValidData(true) {
            return
        }
        self.enableRegisterButton(false)
        self.showLoading()
        firstly{
            return self.signup()
        }.then { _   -> Void  in
            self.view.endEditing(true)
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
        }.always {
            self.stopLoading()
            self.enableRegisterButton(true)
        }.catch { (error) in
            let err  = error as NSError
            self.showError(err.localizedDescription, animated: true)
        }
    }
    
    @objc func rightBarButtonClicked(_ sender: UIButton) {
        sender.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        sender.recordAction(.Tap, sourceRef: "Signup-Cancel", sourceType: .Link, targetRef: "SignupOptions", targetType: .View)
        
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
        self.view.endEditing(true)
        if self.mobileSignupProfileView.displayNameTextField.isFirstResponder {
            if let errorMessage = self.mobileSignupProfileView.getDisplayNameError() {
                self.showError(errorMessage, animated: true)
                self.mobileSignupProfileView.showBorder(true, isDisplayName: true)
            }
        }
        if self.mobileSignupProfileView.passwordTextField.isFirstResponder {
            if let errorMessage = self.mobileSignupProfileView.getPasswordError() {
                self.showError(errorMessage, animated: true)
                self.mobileSignupProfileView.showBorder(true, isDisplayName: false)
            }
        }
        if imagePickerManager == nil {
            imagePickerManager = ImagePickerManager(viewController: self, withDelegate: self)
        }
        
        imagePickerManager!.presentDefaultActionSheet(preferredCameraDevice: .front)
    }
    
    func signup()-> Promise<Void> {
        
        let param = AuthService.SignUpParameter(mobileNumber: mobileNumber, mobileCode: mobileCode, mobileVerificationId: mobileVerificationId, mobileVerificationToken: mobileVerficationToken, password: mobileSignupProfileView.passwordTextField.text ?? "", displayName: mobileSignupProfileView.displayNameTextField.text ?? "", inviteCode: Context.getInvitationCode())
        
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
    
    func textFieldDidEndEditing(_ textField: UITextField) {

    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.selectedTextField = textField
        self.mobileSignupProfileView.textFieldDidBeginEditing(textField.tag)
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if !self.isEnabal {
            return true
        }
        if textField.tag == 0 { //Username
//            if let errorMessage = mobileSignupProfileView.getDisplayNameError() {
                //self.showError(errorMessage, animated: true)
                self.mobileSignupProfileView.showBorder(true, isDisplayName: true)
                return true
//            }
        } else {
            if let errorMessage = mobileSignupProfileView.getPasswordError() {
                self.showError(errorMessage, animated: true)
                self.mobileSignupProfileView.showBorder(true, isDisplayName:  false)
                return true
            }
        }
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        textField.text = ""
        self.mobileSignupProfileView.didChangeCharacters(textField)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if textField == self.mobileSignupProfileView.displayNameTextField && textField.text?.length >= Constants.Value.NickNameMaxLength {
            return false
        }
        
        Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.checkValidData), userInfo: nil, repeats: false)
        return true
    }
    
    @objc func checkValidData() {
        if let textField = selectedTextField{
            self.mobileSignupProfileView.didChangeCharacters(textField)
        }
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
    
    func isValidData(_ isShowErrorMessage: Bool = false) -> Bool{
        if isShowErrorMessage {
            if let errorMessage = self.mobileSignupProfileView.getErrorMessage() {
                self.showError(errorMessage, animated: true)
                return false
            }
            return true
        }
        return (self.mobileSignupProfileView.getErrorMessage() == nil)
    }
    
    //MARK: KeyboardWilShow/Hide callback
    @objc func keyboardWillShow(_ notification: Notification) {
        self.handleShowKeyboard(notification)

    }
    func handleShowKeyboard(_ notification: Notification){
        if let userInfo = notification.userInfo {
            if let keyboardSize: CGSize = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.size {
                let contentSize = CGSize(width: self.view.frame.sizeWidth,height: mobileSignupProfileView.registerButton.frame.maxY + keyboardSize.height + Margin.bottom)
                mobileSignupProfileView.scrollView.contentSize = contentSize
                if contentSize.height < mobileSignupProfileView.scrollView.frame.sizeHeight {
                    self.scrollViewDidScroll(mobileSignupProfileView.scrollView)
                }else {
                    let bottomOffset = CGPoint(x: 0, y: self.mobileSignupProfileView.scrollView.contentSize.height + self.mobileSignupProfileView.scrollView.contentInset.bottom - self.mobileSignupProfileView.scrollView.bounds.size.height)
                    self.mobileSignupProfileView.scrollView.setContentOffset(bottomOffset, animated: true)
                   self.scrollViewDidScroll(mobileSignupProfileView.scrollView)
                }
                
            }
        }
    }
    @objc func keyboardWillHide(_ notification: Notification) {
        self.mobileSignupProfileView.scrollView.frame = self.mobileSignupProfileView.bounds
        mobileSignupProfileView.scrollView.contentSize = self.mobileSignupProfileView.bounds.size
    }

    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == self.mobileSignupProfileView.scrollView {
            if self.selectedTextField == mobileSignupProfileView.displayNameTextField && self.mobileSignupProfileView.getDisplayNameError() != nil {
                self.mobileSignupProfileView.showAnimation(mobileSignupProfileView.collectionView)
            }else if self.mobileSignupProfileView.getPasswordError() != nil {
                self.mobileSignupProfileView.showAnimation(mobileSignupProfileView.collectionViewPassword)
            }
            
        }
    }
}
