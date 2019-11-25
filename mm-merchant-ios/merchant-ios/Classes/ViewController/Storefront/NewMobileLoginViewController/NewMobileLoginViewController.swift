//
//  NewMobileLoginViewController.swift
//  merchant-ios
//
//  Created by LongTa on 7/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
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


class NewMobileLoginViewController: MobileLoginViewController {
    
    let scrollView = UIScrollView()
    var isShowingKeyboard = false
    weak var parentController: SignupModeViewController?
    override func viewDidLoad() {
        mobileLoginView = NewMobileLoginView()
        ContentViewHeight = 230
        super.viewDidLoad()
        
        pageAccessibilityId = "LoginMM"
        self.setAccessibilityIdForView("UITB_CA_ACCOUNT", view: mobileLoginView.upperTextField)
        self.setAccessibilityIdForView("UITB_CA_PASSWORD", view: mobileLoginView.lowerTextField)
        self.setAccessibilityIdForView("UIBT_LOGIN", view: mobileLoginView.button)
        
        self.mobileLoginView.upperTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: UIControlEvents.editingChanged)
        self.mobileLoginView.lowerTextField.addTarget(self, action: #selector(self.textFieldDidChange), for: UIControlEvents.editingChanged)
        initAnalyticsViewRecord(
            viewLocation: "Login",
            viewType: "ExclusiveLaunch"
        )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func login(_ sender:UIButton, blockAfterLogin : AnalyticsManager.AnalyticBlockForLoginCompleted?){
        if self.isValidData() {
            var parameters = [String : Any]()
            var username = ""
            if isCodeInput {
                username = "\(mobileLoginView.signupInputView.codeTextField.text!)-\(mobileLoginView.signupInputView.mobileNumberTextField.text!)"
            } else {
                username = mobileLoginView.upperTextField.text?.trim() ?? ""
            }
            username.clean()
            let password = mobileLoginView.lowerTextField.text ?? ""
            parameters["Username"] = username
            parameters["Password"] = password
            sender.isEnabled = false
            self.showLoading()
            
            LoginManager.login(username, password: password).then { [weak self] _ -> Void in
                if let strongSelf = self {
                    strongSelf.mobileLoginView.lowerTextField.resignFirstResponder()
                    strongSelf.mobileLoginView.upperTextField.resignFirstResponder()
                    strongSelf.getProfile()
                    
                    strongSelf.view.endEditing(true)
                    
                    strongSelf.mobileLoginView.borderUpperTF.isHidden = true
                    strongSelf.mobileLoginView.borderLowerTF.isHidden = true
                    
                    strongSelf.dismiss(animated: false, completion: {
                        strongSelf.parentController?.didDisMissLoginView({
                            if let loginAfterBlock = strongSelf.loginAfterCompletion {
                                loginAfterBlock()
                            }
                        })
                    })//Prevent memory leak
                }
                }.always {
                    self.stopLoading()
                }.catch { (error) in
                    let err = error as NSError
                    self.showError(err.localizedDescription, animated: true)
                    
                    blockAfterLogin?(nil)
                    
                    sender.isEnabled = true
                    
                    if self.mobileLoginView.upperTextField.text?.length > 0 &&
                        self.mobileLoginView.lowerTextField.text?.length > 0 {
                        
                        self.mobileLoginView.borderUpperTF.isHidden = false
                        self.mobileLoginView.borderLowerTF.isHidden = false
                    }
                    
                    if !self.isCodeInput{
                        if let isMobile = err.userInfo["isMobile"] as? Bool, isMobile == true{
                            self.showCodeInput()
                        }
                    }
                    if let appCode = err.userInfo["appCode"] as? String, appCode == "MSG_ERR_LOGIN_ATTEMPT_COUNT_EXCEED" {
                        self.dismissKeyboard()
                        self.forgotPasswordClicked(String.localize("MSG_ERR_LOGIN_ATTEMPT_COUNT_EXCEED"))
                    }
            }
        }
    }
    
    override func forgotPassword(_ sender: UIButton){
        super.forgotPassword(sender)
        sender.recordAction(.Tap, sourceRef: "ForgetPassword", sourceType: .Link, targetRef: "ResetPassword", targetType: .Page)
    }
    
    func loginByWeChat(_ sender: UIButton){
        sender.recordAction(.Tap, sourceRef: "WeChat", sourceType: .Button, targetRef: "", targetType: .WeChatLogin)
        if let controller = self.parentController {
            self.dismiss(animated: true) {
                WeChatManager.login(controller)
            }
        } else {
            WeChatManager.login(self)
        }
    }
    
    override func setupLayout() {
        super.setupLayout()
        
        self.mobileLoginView.removeFromSuperview()
        self.scrollView.addSubview(self.mobileLoginView)
        self.mobileLoginView.frame =  CGRect(x: 0, y: self.view.frame.maxY - self.mobileLoginView.bounds.height, width: self.mobileLoginView.bounds.width, height: self.mobileLoginView.bounds.height)
        
        self.scrollView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss as () -> Void)))
        self.scrollView.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: self.view.bounds.height)
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.sizeWidth, height: self.mobileLoginView.frame.maxY)
        self.view.addSubview(self.scrollView)
        self.scrollView.frame =  CGRect(x: 0, y: 0, width: self.scrollView.bounds.width, height: self.scrollView.bounds.height)
        self.scrollView.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.mobileLoginView.upperTextField.becomeFirstResponder()
        scrollView.isHidden = false
    }
    
    //MARK: KeyboardWilShow/Hide callback
    override func keyboardWillShow(_ notification: Notification) {
        isShowingKeyboard = true
        if let info = notification.userInfo, let kbObj = info[UIKeyboardFrameEndUserInfoKey] {
            var kbRect = (kbObj as! NSValue).cgRectValue
            kbRect = self.view.convert(kbRect, from: nil)
            var offset = kbRect.height - (self.view.frame.size.height - (self.mobileLoginView.cornerButton.frame.maxY + 14 + self.mobileLoginView.frame.origin.y))
            if offset < 0 {
                offset = 0
            }
            UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
                self.scrollView.setContentOffset(CGPoint(x: 0, y:offset), animated: true)
            }, completion: { finished in
                Log.debug("keyboard shown!")
                if (self.mobileLoginView.frame.height > self.scrollView.bounds.size.height) {
                    self.scrollView.isScrollEnabled = true
                } else {
                    self.scrollView.isScrollEnabled = false
                }
            })
        }
    }
    
    override func keyboardWillHide(_ notification: Notification) {
        isShowingKeyboard = false
        var frame = self.scrollView.frame
        frame.size.height = self.view.frame.size.height - frame.origin.y
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.scrollView.frame = frame;
        }, completion: { finished in
            Log.debug("keyboard hidded!")
        })
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField ==  self.mobileLoginView.upperTextField  {
            self.mobileLoginView.borderUpperTF.isHidden = true
        }
        
        if textField == self.mobileLoginView.lowerTextField {
            self.mobileLoginView.borderLowerTF.isHidden = true
        }
        
        if self.mobileLoginView.upperTextField.text?.length > 0 && self.mobileLoginView.lowerTextField.text?.length > 0 {
            self.mobileLoginView.button.formatPrimary()
        } else {
            self.mobileLoginView.button.formatDisable(UIColor.white)
        }
    }
    
    //MARK: IncorrectViewDelegate
    func incorrectViewShow(_ isShow: Bool) {}
}

