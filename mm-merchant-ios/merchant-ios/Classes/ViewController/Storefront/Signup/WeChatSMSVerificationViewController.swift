//
//  MobileSignupViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 1/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit
import Alamofire


class WeChatSMSVerificationViewController: MobileSignupViewController {
    override func viewDidLoad() {
        self.viewMode = .wechat
        super.viewDidLoad()
        
        Context.clearInvitationCode()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func checkMobileVerification(_ button: UIButton){
        
        button.initAnalytics(withViewKey: self.analyticsViewRecord.viewKey)
        button.recordAction(.Tap, sourceRef: "Submit", sourceType: .Button, targetRef: "Newsfeed-Home-User", targetType: .View)
    
        
        if let inviteButton = self.verificationCodeView?.inviteButton, button == inviteButton { // user click on invitation code button
            if let mobileNumber = signupInputView.mobileNumberTextField.text, let mobileCode = signupInputView.codeTextField.text, let mobileVerificationToken = signupInputView.activeCodeTextField.text{
                 let mobileVerificationId:String = String(self.mobileVerification.mobileVerificationId)
                firstly {
                    return checkMobileVerifcation(mobileNumber, mobileCode: mobileCode, mobileVerificationId: mobileVerificationId, mobileVerificationToken: mobileVerificationToken)
                    }.then { _ -> Void in
                        
                        self.goToInvitationView()
                    }.catch { (errorType) -> Void in
                        
                }
                
            }
        }else { // user click on submit button
            self.triggerActivationFlow(nil)
        }
        
        
    }
    
    
    
    func triggerActivationFlow(_ inviteCode: String? = nil) {
        
        guard self.isVerificationCodeViewValid() else {
            return
        }
        
        if let mobileNumber = signupInputView.mobileNumberTextField.text, let mobileCode = signupInputView.codeTextField.text, let mobileVerificationToken = self.signupInputView.activeCodeTextField.text{
            let mobileVerificationId:String = String(self.mobileVerification.mobileVerificationId)
            self.showLoading()
            
            firstly {
                return activateWechat(mobileNumber, mobileCode: mobileCode, mobileVerificationId: mobileVerificationId, mobileVerificationToken: mobileVerificationToken, invitationCode: inviteCode)
            }.then { _ -> Promise<User> in
                return UserService.fetchUser(true)
            }.then { user -> Void in
                LoginManager.didRegister(user: user)
                LoginManager.updateUserInfoAfterLogin()
                Context.clearInvitationCode()
                LoginManager.goToStorefront()
                LoginManager.setUserAfterLogin(user)
                
            }.always {
                self.stopLoading()
            }
            
        }
        
    }
    
    func promptInvitationCodeAlert() {
        let alert = UIAlertController(title: nil, message: String.localize("MSG_CA_ERR_INV_CODE_INVALID"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: String.localize("LB_CA_INPUT_RETRY"), style: .default, handler: { (action) in
            self.signupInputView.activeCodeTextField.isEnabled = false //disable to verification code to prevent user change it
            self.signupInputView.activeCodeTextField.becomeFirstResponder()
        }))
        
        
        alert.addAction(UIAlertAction(title: String.localize("LB_CA_GO_REGISTRATION"), style: .default, handler: { (action) in
            self.triggerActivationFlow()
        }))
        alert.view.tintColor = UIColor.alertTintColor()
        self.present(alert, animated: true, completion: nil)
    }
    
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
                            //Context.setShowingPopup111(true)
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
        
        if resp.appCode == "LB_CA_VERCODE_INVALID" {
            
            self.retryAttempt += 1
            
            if self.retryAttempt >= Constants.Value.MaxAttempt {
                self.retryAttempt = 0
                self.verificationCodeView?.isHidden = true
                self.showError(String.localize("MSG_ERR_MOBILE_VERIFICATION_ATTEMPT_COUNT_EXCEED"), animated: true)
            } else {
                self.showError("\(String.localize("LB_CA_VERCODE_INCORRECT_1"))\(Constants.Value.MaxAttempt - self.retryAttempt)\(String.localize("LB_CA_VERCODE_INCORRECT_2"))", animated: true)
                
                self.setBorderTextField(self.signupInputView.activeCodeTextField, isSet: true)
                
            }

        } else if resp.appCode == "MSG_ERR_CS_INVITE_CODE_INVALID" {
            
            self.promptInvitationCodeAlert()
            
        } else {
            
            //For Other errors
            self.retryAttempt = 0
//            self.verificationCodeView?.isHidden = true
            self.signupInputView.resetWithoutCallback()
            
            self.showError(String.localize(resp.appCode), animated: true)
        }
        
        reject?(error)
        
    }

    
    
}
