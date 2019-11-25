//
//  SignupModeViewController.swift
//  merchant-ios
//
//  Created by Alan YU on 22/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit
import Alamofire

enum SignupMode: Int {
    case normal
    case checkout
    case checkoutSwipeToPay
    case profile
    case publicProfile
    case im
    case merchantDetail
    case discovery
    case home
    case mm
    case continueGuestAction
    case couponCenter
    case couponClaimed
}

enum SignUpViewMode: Int  {
    case signUp         // For sign up
    case profile        // For editing profile
    case wechat
}

class SignupModeViewController: MmViewController, MobileLoginDelegate {
    
    var loginAfterCompletion: LoginAfterCompletion? // 登录成功后的回调
    
    var signupMode = SignupMode.normal
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let mode = ssn_Arguments["mode"]?.int, let signupMode = SignupMode(rawValue: mode) {
            self.signupMode = signupMode
        }
    }
    
    //MARK: Actions region
    @objc func mobileLogin(_ button: UIButton) {
        Utils.requestLocationAndPushNotification()
        let newMobileLoginViewController = NewMobileLoginViewController()
        newMobileLoginViewController.mobileLoginDelegate = self
        newMobileLoginViewController.parentController = self
        newMobileLoginViewController.loginAfterCompletion = self.loginAfterCompletion
        newMobileLoginViewController.modalPresentationStyle = .overFullScreen
        let navigationController = MmNavigationController(rootViewController: newMobileLoginViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        present(navigationController, animated: false, completion: nil)
    }
    
    //MARK: Mobile Login Delegate
    func forgotPasswordClicked(_ message: String?) {
        let controller = MobileForgotPasswordViewController()
        controller.loginAfterCompletion = self.loginAfterCompletion
        controller.errorMessage = message
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func didDismissLogin() {}
    
    func didDisMissLoginView(_ completion:(() -> Void)?) {
        dismiss(animated: false, completion: completion)
    }
    
    //MARK: Mobile Signup
    @objc func mobileSignup(_ button : UIButton) {
        Utils.requestLocationAndPushNotification()
        //        Navigator.shared.dopen(Navigator.mymm.website_signup)
        let mobileSignupViewController = SignupSMSViewController()
        mobileSignupViewController.loginAfterCompletion = self.loginAfterCompletion
        //        mobileSignupViewController.signupMode = self.signupMode
        self.navigationController?.push(mobileSignupViewController, animated: true)
    }
    
    @objc func oldSignup() {
        let mobileSignupViewController = MobileSignupViewController()
        mobileSignupViewController.signupMode = self.signupMode
        self.navigationController?.push(mobileSignupViewController, animated: true)
    }
    
    //MARK: Login Service
    
    func loginWeChat(_ sender : Notification) {
        if let userInfo = sender.userInfo {
            if let code = userInfo["Code"] as? String {
                loginWeChatWithCode(code)
            }
        }
    }
    
    func loginWeChatWithCode(_ code : String) {
        var parameters = [String : Any]()
        parameters["AuthorizationCode"] = code
        
        self.showLoading()
        
        AuthService.loginWeChat(parameters){ [weak self] (response) in
            if let strongSelf = self {
                strongSelf.stopLoading()
                
                if response.result.isSuccess {
                    if response.response!.statusCode == 200 {
                        if let token = Mapper<Token>().map(JSONObject: response.result.value) {
                            Log.debug(token)
                            Context.setToken(token.token)
                            Context.setUserKey(token.userKey)
                            
                            if token.isSignup || !token.isActivated {
                                let vc = SignupSMSViewController()
                                vc.viewMode = .wechat
                                vc.loginAfterCompletion = strongSelf.loginAfterCompletion
                                strongSelf.navigationController?.pushViewController(vc, animated: false)
                                strongSelf.recordWeChatAction(isLogin: false)
                            } else {
                                LoginManager.saveLoginState(token)
                                UserService.fetchUser(true).then { (user) -> Void in
                                    LoginManager.setUserAfterLogin(user)
                                    TrackManager.signIn(user.userKey)
                                    strongSelf.recordWeChatAction(isLogin: true)
                                    
                                    strongSelf.dismiss(animated: false, completion: {
                                        NotificationCenter.default.post(name: Constants.Notification.loginSucceed, object: nil)
                                        if let loginAfterBlock = strongSelf.loginAfterCompletion {
                                            loginAfterBlock()
                                        }
                                    })
                                }
                            }
                        }
                    } else {
                        strongSelf.handleError(response, animated: true)
                    }
                } else {
                    strongSelf.showNetworkError(response.result.error, animated: true)
                }
            }
        }
    }
    
    func recordWeChatAction(isLogin: Bool) {
        
    }
    //MARK: Left button
    @objc func wechatButtonClicked(_ button: UIButton){
        WeChatManager.login(self)
    }
    
    //MARK: Send mobile verification
    func sendMobileVerifcation(_ mobileNo: String, mobileCode: String)-> Promise<Any> {
        return Promise { fulfill, reject in
            var parameters = [String : Any]()
            parameters["MobileNumber"] = mobileNo
            parameters["MobileCode"] = mobileCode
            _ = AuthService.sendMobileVerification(parameters) { [weak self] (response) in
                if let strongSelf = self {
                    strongSelf.handleSendMobileVerifcationResponse(fulfill, response: response, reject: reject)
                }
            }
        }
    }
    
    func handleSendMobileVerifcationResponse(_ fulfill: (Any) -> Void, response : DataResponse<Any>, reject : ((Error) -> Void)? = nil){}
    
    //MARK: Check mobile verification, now we only do check mobile verification api for this function. removed wechat activate
    func checkMobileVerifcation(_ mobileNumber: String, mobileCode: String, mobileVerificationId: String, mobileVerificationToken: String)-> Promise<Any> {
        return Promise{ fulfill, reject in
            var parameters = [String : Any]()
            parameters["MobileNumber"] = mobileNumber
            parameters["MobileCode"] = mobileCode
            parameters["MobileVerificationId"] = mobileVerificationId
            parameters["MobileVerificationToken"] = mobileVerificationToken
            parameters["AccessToken"] = Context.getToken()
            
            _ = AuthService.checkMobileVerification(parameters) { [weak self] (response) in
                if let strongSelf = self {
                    Log.debug("Repsone : \(response)")
                    strongSelf.handleCheckMobileVerifcationResponse(fulfill, response: response, reject: reject)
                }
            }
            
        }
    }
    
    func handleCheckMobileVerifcationResponse(_ fulfill: (Any) -> Void, response : DataResponse<Any>, reject : ((Error) -> Void)? = nil){}

    func moveToHomePage() {
        ssn_home()
    }

    func isPhoneValid(_ phone: String , countryCode: String) -> Bool {
        if countryCode == Constants.CountryMobileCode.HK {
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.MobilePhone.HongKong, text: phone).isEmpty || phone.length != 8{
                return false
            }
        } else if countryCode == Constants.CountryMobileCode.DEFAULT {
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.MobilePhone.China, text: phone).isEmpty || phone.length != 11{
                return false
            }
        }
        return true
    }
    
    func validatePhoneNumber(_ phoneNumber: String?, countryCode: String?) -> String? {
        if let text =  phoneNumber, text.length > 0 {
            guard !(text.length < Constants.MobileNumber.MIN_LENGTH) && text.isNumberic() && self.isPhoneValid(text, countryCode: countryCode ?? "") else {
                return String.localize("MSG_ERR_CA_MOBILE_PATTERN")
            }
        } else {
            return String.localize("LB_CA_INPUT_MOBILE")
        }
        return nil
    }
}

