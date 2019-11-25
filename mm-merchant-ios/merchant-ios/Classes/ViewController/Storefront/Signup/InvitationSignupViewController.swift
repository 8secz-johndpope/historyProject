//
//  InvitationSignUpViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 4/14/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper
import Alamofire

class InvitationSignupViewController: MmViewController {
    
    private let HeightInvitationView: CGFloat = 285
    private let invitationView = UIView()
    private let invitationCodeTextField = UITextField()
    private let invitationTitleLabel = UILabel()
    private let skipButton = UIButton(type: .custom)
    private let lineView = UIView()
    private let submitButton = UIButton(type: .custom)
    var scrollView = UIScrollView()
    var signupMode = SignupMode.normal
    var viewMode = SignUpViewMode.signUp
    
    var mobileNumber = ""
    var mobileCode = ""
    var mobileVerificationId = 0
    var mobileVerficationToken = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(white: 0, alpha: 0.6)
        self.initializeInvitationView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(InvitationSignupViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(InvitationSignupViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil);
        
        NotificationCenter.default.addObserver(self, selector: #selector(InvitationSignupViewController.keyboardDidHide(_:)), name: NSNotification.Name.UIKeyboardDidHide, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(InvitationSignupViewController.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil);
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.invitationCodeTextField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    
    //MARK: - View Data - View Actions
    
    
    
    @objc func dismissView() {
        dismissKeyboard()
        
        UIView.animate(
            withDuration: 0.3,
            animations: { [weak self] () -> Void in
                if let strongSelf = self {
                    strongSelf.invitationView.frame = CGRect(x: 0, y: strongSelf.view.bounds.height, width: strongSelf.view.bounds.width, height: strongSelf.HeightInvitationView)
                }
            },
            completion: { [weak self]  (success) -> Void in
                if let strongSelf = self {
                    
                    strongSelf.dismiss(animated: false, completion: nil)
                }
            }
        )
    }
    
    func initializeInvitationView() {
        
        let viewBound = self.view.bounds
        
        let dismissViewGesture = UITapGestureRecognizer(target: self, action: #selector(InvitationSignupViewController.dismissView))
        
        self.scrollView.addGestureRecognizer(dismissViewGesture)
        self.scrollView.backgroundColor = UIColor.clear
        self.scrollView.frame = self.view.bounds
        self.view.addSubview(self.scrollView)
        
        invitationView.frame = CGRect(x: 0, y: viewBound.sizeHeight - HeightInvitationView, width: viewBound.sizeWidth, height: HeightInvitationView)
        invitationView.backgroundColor = UIColor.white
        let dismissKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(InvitationSignupViewController.dismissKeyboard))
        invitationView.addGestureRecognizer(dismissKeyboardGesture)
        
        let paddingLeftRightContent: CGFloat = 16
        let topPaddingInvitationTitle: CGFloat = 15
        let heightInvitationTitle: CGFloat = 20
        
        invitationTitleLabel.frame = CGRect(x: paddingLeftRightContent, y: topPaddingInvitationTitle, width: viewBound.sizeWidth - 2 * paddingLeftRightContent, height: heightInvitationTitle)
        invitationTitleLabel.textAlignment = .center
        invitationTitleLabel.text = String.localize("LB_EXCL_INV_CODE")
        invitationTitleLabel.applyFontSize(15, isBold: false)
        invitationTitleLabel.textColor = UIColor.secondary2()
        invitationView.addSubview(invitationTitleLabel)
        
        
        
        
        let heightCodeTextField: CGFloat = 44
        let topPaddingInvitationCodeTextField: CGFloat = 15
        
        let label = UILabel()
        label.textColor = UIColor.secondary2()
        label.applyFontSize(15, isBold: false)
        label.text = String.localize("LB_EXCL_ENTER_INV_CODE")
        
        let width = StringHelper.getTextWidth(label.text ?? "", height: heightCodeTextField, font: label.font)
        let marginLeft = CGFloat(25)
        label.frame = CGRect(x: marginLeft, y: invitationTitleLabel.frame.maxY + topPaddingInvitationCodeTextField, width: width, height: heightCodeTextField)
        invitationView.addSubview(label)
        
        invitationCodeTextField.frame = CGRect(x: label.frame.maxX, y: invitationTitleLabel.frame.maxY + topPaddingInvitationCodeTextField, width: viewBound.sizeWidth - 2 * paddingLeftRightContent, height: heightCodeTextField)
        invitationCodeTextField.format()
        invitationCodeTextField.returnKeyType = .done
        invitationCodeTextField.placeholder = ""
        invitationCodeTextField.keyboardType = .default
        invitationCodeTextField.borderStyle = .none
        invitationCodeTextField.layer.borderColor = UIColor.clear.cgColor
        invitationCodeTextField.addTarget(self, action: #selector(InvitationSignupViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
        invitationView.addSubview(invitationCodeTextField)
        
        lineView.backgroundColor = UIColor.secondary1()
        lineView.frame = CGRect(x: paddingLeftRightContent, y: invitationCodeTextField.frame.maxY, width: viewBound.sizeWidth - 2 * paddingLeftRightContent, height: 1)
        invitationView.addSubview(lineView)
        
        let heightSubmitButton: CGFloat = 45
        let topPaddingSubmitButton: CGFloat = 15
        submitButton.frame = CGRect(x: paddingLeftRightContent, y: invitationCodeTextField.frame.maxY + topPaddingSubmitButton, width: viewBound.sizeWidth - 2 * paddingLeftRightContent, height: heightSubmitButton)
        submitButton.formatDisable()
        submitButton.addTarget(self, action: #selector(InvitationSignupViewController.didClickOnSubmitButton), for: .touchUpInside)
        submitButton.setTitle(String.localize("LB_NEXT"), for: UIControlState())
        invitationView.addSubview(submitButton)
        
        let sizeSkipButton: CGSize = CGSize(width: 40, height: 20)
        let topPaddingSkipButton: CGFloat = 15
        skipButton.frame = CGRect(x: viewBound.sizeWidth - paddingLeftRightContent - sizeSkipButton.width, y: submitButton.frame.maxY + topPaddingSkipButton, width: sizeSkipButton.width, height: sizeSkipButton.height)
        skipButton.setTitle(String.localize("LB_SKIPPED"), for: UIControlState())
        skipButton.accessibilityIdentifier = "skipButton"
        skipButton.addTarget(self, action: #selector(InvitationSignupViewController.didClickOnSkipButton), for: .touchUpInside)
        skipButton.formatWhite()
        invitationView.addSubview(skipButton)
        
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.sizeWidth, height: self.invitationView.frame.maxY)
        self.scrollView.addSubview(invitationView)
    }
    
    @objc func didClickOnSkipButton() {
        skipButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        skipButton.recordAction(.Tap, sourceRef: "Signup-Skip", sourceType: .Button, targetRef: "SignupInfo", targetType: .View)
        if self.viewMode == SignUpViewMode.wechat {
            self.triggerActivationFlow(nil)
        } else {
            self.goToRegisterProfilePage()
        }
    }
    

    
    func goToRegisterProfilePage() {
        let mobileSignupProfileViewController = NewMobileSignupProfileViewController()
        mobileSignupProfileViewController.signupMode = self.signupMode
        mobileSignupProfileViewController.mobileNumber = self.mobileNumber
        mobileSignupProfileViewController.mobileCode = self.mobileCode
        mobileSignupProfileViewController.mobileVerificationId = self.mobileVerificationId
        mobileSignupProfileViewController.mobileVerficationToken = self.mobileVerficationToken
        self.navigationController?.push(mobileSignupProfileViewController, animated: true)
    }
    
    func checkInviteCodeService(_ inviteCode: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            InviteService.checkInviteCode(inviteCode, completion: {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                        } else {
                            strongSelf.handleError(response, animated: true, reject: reject) // optional now.
                        }
                        
                    } else{
                        strongSelf.handleError(response, animated: true, reject: reject)
                    }
                }
                })
        }
    }
    
    @objc func didClickOnSubmitButton() {
        
        submitButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        submitButton.recordAction(.Tap, sourceRef: "InviteCode-Next", sourceType: .Button, targetRef: "SignupInfo", targetType: .View)
        
        if let invite = self.invitationCodeTextField.text, invite.length > 0 {
            self.checkInviteCodeService(invite).then { _  -> Void in
                Context.setInvitationCode(invite)
                if self.viewMode == .wechat {
                    self.triggerActivationFlow(invite)
                }else {
                    self.goToRegisterProfilePage()
                }
                
            }.catch { (errorType) in
                // prompt and check
                
                let alert = UIAlertController(title: nil, message: String.localize("MSG_CA_ERR_INV_CODE_INVALID"), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: String.localize("LB_CA_INPUT_RETRY"), style: .default, handler: { (action) in
                    self.invitationCodeTextField.becomeFirstResponder()
                }))
                
                alert.addAction(UIAlertAction(title: String.localize("LB_CA_GO_REGISTRATION"), style: .default, handler: { (action) in
                    if self.viewMode == .wechat {
                        self.triggerActivationFlow(nil)
                    }else {
                        self.goToRegisterProfilePage()
                    }
                }))
                
                alert.view.tintColor = UIColor.alertTintColor()
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func triggerActivationFlow(_ inviteCode: String? = nil) {
        
        self.showLoading()
        firstly {
            return activateWechat(mobileNumber, mobileCode: mobileCode, mobileVerificationId: String(self.mobileVerificationId), mobileVerificationToken: mobileVerficationToken, invitationCode: inviteCode)
            }.then { _ -> Promise<User> in
                return UserService.fetchUser(true)
            }.then { user -> Void in
                LoginManager.updateUserInfoAfterLogin()
                Context.clearInvitationCode()
                LoginManager.goToStorefront()
                LoginManager.setUserAfterLogin(user)
                
            }.always {
                self.stopLoading()
            }
        
    }
    
    //MARK: - TextField Delegate
    @objc func textFieldDidChange(_ sender: UITextField) {
        if let text = self.invitationCodeTextField.text {
            if text.length > 0 {
                self.submitButton.isEnabled = true
                self.submitButton.formatPrimary()
            }else {
                self.submitButton.isEnabled = false
                self.submitButton.formatDisable()
            }
        }
    }
    
    //MARK: - Wechat Methods
    
    func activateWechat(_ mobileNumber: String, mobileCode: String, mobileVerificationId: String, mobileVerificationToken: String, invitationCode: String?) -> Promise<Any> {
        
        return Promise{ fulfill, reject in
            var parameters = [String : Any]()
            parameters["MobileNumber"] = mobileNumber
            parameters["MobileCode"] = mobileCode
            parameters["MobileVerificationId"] = mobileVerificationId
            parameters["MobileVerificationToken"] = mobileVerificationToken
            parameters["AccessToken"] = Context.getToken()
            if let invite = invitationCode, invite.length > 0 {
                parameters[AuthService.SignUpParameter.InviteCode] = invite
            }
            
            AuthService.activateWeChat(parameters) { [weak self] (response) in
                if let strongSelf = self {
                    
                    if response.result.isSuccess && response.response?.statusCode == 200 {
                        
                        if let token = Mapper<Token>().map(JSONObject: response.result.value) {
                            Log.debug(token)
                            LoginManager.saveLoginState(token)
                            UserService.updateDevice(
                                JPUSHService.registrationID(),
                                deviceIdPrevious: nil,
                                completion: nil
                            )
                            fulfill("OK")
                        }
                        
                    } else {
                        strongSelf.handleActivationResponse(fulfill, response: response, reject: reject)
                    }
                } else {
                    reject(response.result.error ?? NSError(domain: "", code: 0, userInfo: nil))
                }
            }
            
            
        }
    }
    
    func handleActivationResponse(_ fulfill: (Any) -> Void, response: DataResponse<Any>, reject: ((Error) -> Void)?) {
        
        guard response.result.isSuccess else {
            if let reject = reject, let error = response.result.error{
                reject(error)
            }
            return
        }
        
        guard let resp = Mapper<ApiResponse>().map(JSONObject: response.result.value) else {
            let error = NSError(domain: "", code: response.response?.statusCode ?? 0, userInfo: nil)
            reject?(error)
            return
        }
        
        let error = NSError(domain: "", code: response.response?.statusCode ?? 0, userInfo: ["AppCode": resp.appCode])
        
        self.showError(String.localize(resp.appCode), animated: true)
        
        reject?(error)
        
    }
    

    
    //MARK: - Keyboard Delegate
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.setContentOffset(CGPoint(x:0,y: 0), animated: true)
        scrollView.scrollIndicatorInsets = contentInset
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y)
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
      
            if let keyboardFrame = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
                let keyboardSize = keyboardFrame.cgRectValue.size
                let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height + 120, right:  0.0)
                //scrollView.contentInset = contentInset
                scrollView.setContentOffset(CGPoint(x:0,y: keyboardSize.height), animated: true)
                scrollView.scrollIndicatorInsets = contentInset
            }
    }
    
    @objc func keyboardDidShow(_ sender: Notification) {
        self.scrollView.isScrollEnabled = false
    }
    
    @objc func keyboardDidHide(_ sender: Notification) {
        self.scrollView.isScrollEnabled = true
    }

}
