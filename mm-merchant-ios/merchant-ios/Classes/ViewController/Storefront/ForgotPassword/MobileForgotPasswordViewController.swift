//
//  MobileForgotPasswordViewController.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 24/2/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//
import Foundation
import ObjectMapper
import PromiseKit
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

class MobileForgotPasswordViewController : SignupModeViewController, SwipeSMSDelegate, UITextFieldDelegate, SelectGeoCountryDelegate, UIPickerViewDataSource, PickerViewDelegate, RequestSMSDelegate {
    private final let WidthItemBar : CGFloat = 30
    private final let HeightItemBar : CGFloat = 25
    private final let PaddingViewPinCode : CGFloat = 20
    
    var mobileForgotPasswordInputView : MobileForgotPasswordInputView!
    var mobileVerification = MobileVerification()
    var isValidCode : Bool = false
    var geoCountries : [GeoCountry] = []
    var isDetectingCountry : Bool = false
    var retryAttempt = 0
    var countryPicker = CountryPickerView()
    var editingTextfield : UITextField?
    var errorMessage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createSubviews()
        self.createBackButton()
        self.title = String.localize("LB_CA_RESET_PW")
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MobileForgotPasswordViewController.dissmissKeyboard))
        mobileForgotPasswordInputView.addGestureRecognizer(tapGesture)
        countryPicker.delegate = self
        countryPicker.dataSource = self
        loadGeo()
    }
    
    func createSubviews() {
        mobileForgotPasswordInputView = MobileForgotPasswordInputView(frame: CGRect(x: 0, y: StartYPos, width: self.view.bounds.width , height: self.view.bounds.height - 64))
        self.view.addSubview(mobileForgotPasswordInputView)
        mobileForgotPasswordInputView.signupInputView.hideCountryButton(true)
        mobileForgotPasswordInputView.signupInputView.countryTextField.inputView = self.countryPicker
        mobileForgotPasswordInputView.signupInputView.countryTextField.delegate = self
        mobileForgotPasswordInputView.signupInputView.codeTextField.text = Constants.CountryMobileCode.DEFAULT
        mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.becomeFirstResponder()
        mobileForgotPasswordInputView.signupInputView.codeTextField.delegate = self
        
        mobileForgotPasswordInputView.signupInputView.delegate = self
        mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.delegate = self
        mobileForgotPasswordInputView.passwordConfirmTextField.delegate = self
        mobileForgotPasswordInputView.passwordTextField.delegate = self
        mobileForgotPasswordInputView.signupInputView.activeCodeTextField.delegate = self
        self.mobileForgotPasswordInputView.passwordTextField.isEnabled = true
        self.mobileForgotPasswordInputView.passwordConfirmTextField.isEnabled = true
        self.mobileForgotPasswordInputView.submitButton.addTarget(self, action: #selector(self.buttonSubmitClicked), for: UIControlEvents.touchUpInside)
        self.mobileForgotPasswordInputView.submitButton.formatDisable(UIColor.white)
        self.mobileForgotPasswordInputView.submitButton.isUserInteractionEnabled = false
        
        setTargetTextField(mobileForgotPasswordInputView.signupInputView.mobileNumberTextField)
        setTargetTextField(mobileForgotPasswordInputView.signupInputView.activeCodeTextField)
        setTargetTextField(mobileForgotPasswordInputView.passwordTextField)
        setTargetTextField(mobileForgotPasswordInputView.passwordConfirmTextField)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(MobileForgotPasswordViewController.keyboardWillShow), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(MobileForgotPasswordViewController.keyboardDidShow), name:NSNotification.Name.UIKeyboardDidShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(MobileForgotPasswordViewController.keyboardWillHide), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let message = errorMessage {
            self.showError(message, animated: true)
            self.errorMessage = nil
        }
    }
    
    //MARK: Keyboard Management
    
    func setTargetTextField(_ textField: UITextField) {
        textField.addTarget(self, action: #selector(MobileForgotPasswordViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
    }
    
    @objc func dissmissKeyboard() {
        self.view.endEditing(true)
    }
    
    func setEnableForInputFields(_ isEnable: Bool) {
        self.mobileForgotPasswordInputView.signupInputView.countryTextField.isEnabled = isEnable
        self.mobileForgotPasswordInputView.signupInputView.codeTextField.isEnabled = isEnable
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        let contentInset = UIEdgeInsets.zero;
        mobileForgotPasswordInputView.scrollView.contentInset = contentInset
        mobileForgotPasswordInputView.scrollView.scrollIndicatorInsets = contentInset
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
        self.handleShowingKeyboard(sender)
    }
    
    @objc func keyboardDidShow(_ sender: Notification) {
        self.handleShowingKeyboard(sender)
    }
    func handleShowingKeyboard(_ sender: Notification){
        let scrollView = self.mobileForgotPasswordInputView.scrollView
        if let keyboardFrame = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
            let keyboardSize = keyboardFrame.cgRectValue.size
            scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            
            let bottomOffset = CGPoint(x: 0.0, y: scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom)
            
            let scrollToBottom = !(self.mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.isFirstResponder || self.mobileForgotPasswordInputView.signupInputView.countryTextField.isFirstResponder || self.mobileForgotPasswordInputView.signupInputView.codeTextField.isFirstResponder)
            
            if scrollToBottom {
                scrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
    }
    //MARK: SwipeSMSDelegate
    
    func validateMobileText(_ isHighlight: Bool, message: String? = nil) {
        if isHighlight {
            self.showError(message ?? "", animated: true)
            mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.becomeFirstResponder()
            mobileForgotPasswordInputView.signupInputView.borderTF.isHidden = false
        } else {
            mobileForgotPasswordInputView.signupInputView.borderTF.isHidden = true
        }
    }
    
    func invalidSwipe() {
        if let textMobilePhone = mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text, textMobilePhone.length > 0, let countryCode = mobileForgotPasswordInputView.signupInputView.codeTextField.text {
            if !self.isPhoneValid(textMobilePhone, countryCode: countryCode) {
                validateMobileText(true, message: String.localize("MSG_ERR_CA_MOBILE_PATTERN"))
            } else {
                validateMobileText(false)
            }
        } else {
            validateMobileText(true, message:String.localize("MSG_ERR_MOBILE_NIL"))
        }
    }
    
    //MARK: - RequestSMS Delegate
    func validatePhoneNumber() -> Bool {
        if let message = self.validatePhoneNumber(mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text, countryCode: mobileForgotPasswordInputView.signupInputView.codeTextField.text)  {
            validateMobileText(true, message: message)
            return false
        }
        return true
    }
    
    func startSMS() {
        mobileForgotPasswordInputView.signupInputView.requestSMSButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        mobileForgotPasswordInputView.signupInputView.requestSMSButton.recordAction(.Tap, sourceRef: "MobileVerification", sourceType: .Button, targetRef: "Code", targetType: .Table)
        if let mobileNo = mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text, let mobileCode = mobileForgotPasswordInputView.signupInputView.codeTextField.text{
            Log.debug("startSMS")
            
            isValidCode = false
            self.setEnableForInputFields(false)
            self.mobileForgotPasswordInputView.signupInputView.activeCodeTextField.text = ""
            if self.isValidPhoneNumber() {
                firstly {
                    return sendMobileVerifcation(mobileNo, mobileCode: mobileCode)
                    }.then { _ -> Void in
                        self.mobileForgotPasswordInputView.signupInputView.activeCodeTextField.becomeFirstResponder()
                }
            } else {
                self.mobileForgotPasswordInputView.signupInputView.resetWithoutCallback()
            }
        }
    }
    
    override func handleSendMobileVerifcationResponse(_ fulfill: (Any) -> Void, response : DataResponse<Any>, reject : ((Error) -> Void)? = nil){
        if response.result.isSuccess {
            if response.response?.statusCode == 200 {
                if let mobileVerification = Mapper<MobileVerification>().map(JSONObject: response.result.value){
                    self.mobileVerification = mobileVerification
                    self.mobileForgotPasswordInputView.signupInputView.borderTF.isHidden = true
                }
                
                fulfill("OK" as Any)
            } else {
                self.handleError(response, animated: true, reject: reject)
                self.mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.becomeFirstResponder()
                self.mobileForgotPasswordInputView.signupInputView.borderTF.isHidden = false
                self.mobileForgotPasswordInputView.signupInputView.resetWithoutCallback()
                self.setEnableForInputFields(true)
            }
        } else {
            self.mobileForgotPasswordInputView.signupInputView.resetWithoutCallback()
            self.handleError(response, animated: true, reject: reject)
            self.setEnableForInputFields(true)
        }
    }
    
    var hasResentSMS = false
    func resetSMS() {
        Log.debug("resetSMS")
        self.setEnableForInputFields(true)
        hasResentSMS = true
    }
    
    func beginSwipe() {
        validateMobileText(false)
        self.setEnableForInputFields(false)
        self.dissmissKeyboard()
    }
    
    //MARK: API Service
    func sendResetPassword()-> Promise<Any> {
        return Promise{ fulfill, reject in
            var parameters = [String : Any]()
            parameters["MobileNumber"] = mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text
            parameters["MobileCode"] = mobileForgotPasswordInputView.signupInputView.codeTextField.text
            parameters["MobileVerificationId"] = self.mobileVerification.mobileVerificationId
            parameters["MobileVerificationToken"] = self.mobileForgotPasswordInputView.signupInputView.activeCodeTextField.text
            parameters["Password"] = self.mobileForgotPasswordInputView.passwordConfirmTextField.text
            AuthService.resetPassword(parameters) { [weak self] (response) in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                    if response.result.isSuccess{
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response)
                        }
                    } else {
                        strongSelf.handleError(response, animated: true, reject: reject)
                    }
                }
            }
        }
    }
    
    override func handleCheckMobileVerifcationResponse(_ fulfill: (Any) -> Void, response: DataResponse<Any>, reject: ((Error) -> Void)?) {
        if response.result.isSuccess {
            if response.response?.statusCode == 200 {
                fulfill("OK" as Any)
                mobileForgotPasswordInputView.signupInputView.activeCodeTextField.shouldHighlight(false)
            } else{
                self.handleAttemptCount()
                self.mobileForgotPasswordInputView.signupInputView.resetWithoutCallback()
                mobileForgotPasswordInputView.signupInputView.activeCodeTextField.becomeFirstResponder()
                mobileForgotPasswordInputView.signupInputView.activeCodeTextField.shouldHighlight(true)
                if let reject = reject{
                    var statusCode = 0
                    if let code = response.response?.statusCode {
                        statusCode = code
                    }
                    
                    let error = NSError(domain: "", code: statusCode, userInfo: nil)
                    reject(error)
                }
            }
        } else {
            if let reject = reject, let error = response.result.error{
                reject(error)
            }
        }
    }
    
    func handleAttemptCount() {
        self.retryAttempt += 1
        if self.retryAttempt >= Constants.Value.MaxAttempt {
            self.retryAttempt = 0
            self.showError(String.localize("MSG_ERR_MOBILE_VERIFICATION_ATTEMPT_COUNT_EXCEED"), animated: true)
            
        } else {
            self.showError("\(String.localize("LB_CA_VERCODE_INCORRECT_1")) \(Constants.Value.MaxAttempt - self.retryAttempt) \(String.localize("LB_CA_VERCODE_INCORRECT_2"))", animated: true)
        }
    }
    
    
    @objc func buttonSubmitClicked(_ sender: UIButton) {
        self.view.endEditing(true)
        if let mobileNumber = mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text, let mobileCode = mobileForgotPasswordInputView.signupInputView.codeTextField.text, let mobileVerificationToken = mobileForgotPasswordInputView.signupInputView.activeCodeTextField.text{
            let mobileVerificationId:String = String(self.mobileVerification.mobileVerificationId)
            if isValidData() {
                self.showLoading()
                firstly{
                    return checkMobileVerifcation(mobileNumber, mobileCode: mobileCode, mobileVerificationId: mobileVerificationId, mobileVerificationToken: mobileVerificationToken)
                    }.then { _ -> Void in
                        self.isValidCode = true
                        self.retryAttempt = 0
                        firstly{
                            return self.sendResetPassword()
                            }.then { _ -> Void in
                                self.login()
                        }
                    }.catch { (errorType) -> Void in
                        self.stopLoading()
                }
            }
        }
    }
    
    //MARK: Validation Region
    
    func isValidPhoneNumber() -> Bool{
        if mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text?.length < 1 {
            self.showError(String.localize("MSG_ERR_MOBILE_NIL"), animated: true)
            return false
        }
        if mobileForgotPasswordInputView.signupInputView.codeTextField.text?.length < 1 {
            self.showError(String.localize("MSG_ERR_COO_NIL"), animated: true)
            return false
        }
        if !self.isPhoneValid(mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text!, countryCode: mobileForgotPasswordInputView.signupInputView.codeTextField.text!) {
            self.showError(String.localize("MSG_ERR_CA_MOBILE_PATTERN"), animated: true)
            return false
        }
        return true
    }
    
    func styleErrorPassword(_ textField: UITextField, message: String) {
        self.showError(message, animated: true)
        textField.shouldHighlight(true, isAddBorderView: true)
        textField.becomeFirstResponder()
    }
    
    func isValidPassword()-> Bool {
        if mobileForgotPasswordInputView.passwordTextField.text?.length < 1 {
            styleErrorPassword(mobileForgotPasswordInputView.passwordTextField, message: String.localize("MSG_ERR_CA_PW_NIL"))
            return false
        }
        if mobileForgotPasswordInputView.passwordTextField.text!.length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Password, text: mobileForgotPasswordInputView.passwordTextField.text).isEmpty {
            styleErrorPassword(mobileForgotPasswordInputView.passwordTextField, message: String.localize("MSG_ERR_CA_PW_PATTERN"))
            return false
        }
        mobileForgotPasswordInputView.passwordTextField.shouldHighlight(false, isAddBorderView: true)
        return true
    }
    
    func isValidConfirmPassword() -> Bool {
        if mobileForgotPasswordInputView.passwordConfirmTextField.text?.length < 1 {
            styleErrorPassword(mobileForgotPasswordInputView.passwordConfirmTextField, message: String.localize("MSG_ERR_CA_PW_NIL"))
            return false
        }
        if mobileForgotPasswordInputView.passwordConfirmTextField.text!.length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Password, text: mobileForgotPasswordInputView.passwordConfirmTextField.text).isEmpty {
            styleErrorPassword(mobileForgotPasswordInputView.passwordConfirmTextField, message: String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"))
            return false
        }
        if mobileForgotPasswordInputView.passwordConfirmTextField.text != mobileForgotPasswordInputView.passwordTextField.text {
            styleErrorPassword(mobileForgotPasswordInputView.passwordConfirmTextField, message: String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"))
            return false
        }
        mobileForgotPasswordInputView.passwordConfirmTextField.shouldHighlight(false, isAddBorderView: true)
        return true
    }
    
    func isValidData() -> Bool {
        if mobileForgotPasswordInputView.signupInputView.activeCodeTextField.text?.length < 1{
            self.showError(String.localize("MSG_ERR_REQUIRED_FIELD_MISSING"), animated: true)
            mobileForgotPasswordInputView.signupInputView.activeCodeTextField.shouldHighlight(true)
            mobileForgotPasswordInputView.signupInputView.activeCodeTextField.becomeFirstResponder()
            return false
        }
        mobileForgotPasswordInputView.signupInputView.activeCodeTextField.shouldHighlight(false)
        
        if !self.isValidPassword() {
            return false
        }
        
        if !self.isValidConfirmPassword() {
            return false
        }
        if !self.validatePhoneNumber() {
            return false
        }
        return true
    }
    
    @objc func updateHint(){
        self.mobileForgotPasswordInputView.didChangeCharacters(mobileForgotPasswordInputView.passwordTextField)
    }
    
    @objc func updateSwipeButton() {
        self.updateConfirmButton()
        if isDetectingCountry {
            mobileForgotPasswordInputView.signupInputView.setEnableRequestSMSButton(false, titleColor: nil)
            return
        }
        if let text = mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text {
            if (text.length < Constants.MobileNumber.MIN_LENGTH) {
                mobileForgotPasswordInputView.signupInputView.setEnableRequestSMSButton(true, titleColor: nil)
                return
            }
            
            if !text.isNumberic() {
                mobileForgotPasswordInputView.signupInputView.setEnableRequestSMSButton(true, titleColor: nil)
                return
            }
            if !self.isPhoneValid(text, countryCode: mobileForgotPasswordInputView.signupInputView.codeTextField.text ?? "") {
                mobileForgotPasswordInputView.signupInputView.setEnableRequestSMSButton(true, titleColor: nil)
                return
            }
        }
        let countries = self.geoCountries.filter({$0.mobileCode == mobileForgotPasswordInputView.signupInputView.codeTextField.text})
        mobileForgotPasswordInputView.signupInputView.setEnableRequestSMSButton((countries.count > 0), titleColor: nil)
    }
    
    func updateConfirmButton() {
        if self.mobileForgotPasswordInputView.signupInputView.activeCodeTextField.text?.length > 0 && self.mobileForgotPasswordInputView.passwordTextField.text?.length > 0 && self.mobileForgotPasswordInputView.passwordConfirmTextField.text!.length > 0 {
            self.mobileForgotPasswordInputView.submitButton.formatPrimary()
            self.mobileForgotPasswordInputView.submitButton.isUserInteractionEnabled = true
        }else {
            self.mobileForgotPasswordInputView.submitButton.formatDisable(UIColor.white)
            self.mobileForgotPasswordInputView.submitButton.isUserInteractionEnabled = false
        }
    }
    //MARK: UITextFieldDelegate
    @objc func textFieldDidChange(_ textField: UITextField) {
        switch textField {
        case mobileForgotPasswordInputView.signupInputView.mobileNumberTextField:
            mobileForgotPasswordInputView.signupInputView.borderTF.isHidden = true
            
            break
        case mobileForgotPasswordInputView.signupInputView.activeCodeTextField:
            mobileForgotPasswordInputView.signupInputView.activeCodeTextField.setStyleDefault()
            self.updateConfirmButton()
            break
        case mobileForgotPasswordInputView.passwordTextField:
            mobileForgotPasswordInputView.passwordTextField.setStyleDefault()
            self.updateConfirmButton()
            break
        case mobileForgotPasswordInputView.passwordConfirmTextField:
            
            mobileForgotPasswordInputView.passwordConfirmTextField.setStyleDefault()
            self.updateConfirmButton()
            break
        default:
            break
        }
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch textField.tag {
            
        case SignupTextFieldTag.phoneNumber.rawValue:
            mobileForgotPasswordInputView?.signupInputView.setEnableRequestSMSButton(true, titleColor: nil)
            break
        case mobileForgotPasswordInputView.passwordTextField.tag:
            mobileForgotPasswordInputView.passwordTextField.text = ""
            self.updateConfirmButton()
            self.updateHint()
        case mobileForgotPasswordInputView.passwordConfirmTextField.tag:
            self.updateConfirmButton()
            
        default:
            break
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        Log.debug("location: \(range.location) string: \(string)")
        switch textField.tag {
        case mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.tag: //Mobile number
            if !mobileForgotPasswordInputView.signupInputView.isTimerCounting() {
                Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MobileForgotPasswordViewController.updateSwipeButton), userInfo: nil, repeats: false)
            }
            break
        case mobileForgotPasswordInputView.signupInputView.codeTextField.tag: //Mobile Code
            if string == "" && range.location == 0 { //Don't allow todelete +
                return false
            }
            if !isDetectingCountry {
                isDetectingCountry = true
                mobileForgotPasswordInputView.signupInputView.setEnableRequestSMSButton(false, titleColor: nil)
                Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(MobileForgotPasswordViewController.detectCountry), userInfo: nil, repeats: false)
            }
            break
        case SignupTextFieldTag.countryName.rawValue:
            return false
        case mobileForgotPasswordInputView.passwordTextField.tag:
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(MobileForgotPasswordViewController.updateHint), userInfo: nil, repeats: false)
        default:
            break
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        editingTextfield = textField
        if (textField == mobileForgotPasswordInputView.passwordTextField) {
            self.mobileForgotPasswordInputView.textFieldDidBeginEditing(mobileForgotPasswordInputView.passwordTextField.tag)
            return
        }
        if (textField == mobileForgotPasswordInputView.passwordConfirmTextField) {
            mobileForgotPasswordInputView.passwordConfirmTextField.shouldHighlight(false)
            return
        }
        if (textField == mobileForgotPasswordInputView.signupInputView.activeCodeTextField){
            return
        }
        if hasResentSMS {
            hasResentSMS = false
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField.tag {
        case mobileForgotPasswordInputView.passwordTextField.tag:
            
            if let errorMessage = mobileForgotPasswordInputView.getPasswordError() {
                self.showError(errorMessage, animated: true)
                self.mobileForgotPasswordInputView.passwordTextField.shouldHighlight(true)
            }
            else {
                if mobileForgotPasswordInputView.passwordConfirmTextField.text?.length > 0 && mobileForgotPasswordInputView.passwordTextField.text != mobileForgotPasswordInputView.passwordConfirmTextField.text{
                    self.showError(String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"), animated: true)
                    self.mobileForgotPasswordInputView.passwordConfirmTextField.shouldHighlight(true)
                }
            }
            
            textField.isSecureTextEntry = false
            textField.isSecureTextEntry = true
            break
        case mobileForgotPasswordInputView.passwordConfirmTextField.tag:
            textField.isSecureTextEntry = false
            textField.isSecureTextEntry = true
            if mobileForgotPasswordInputView.passwordConfirmTextField.text?.length == 0 {
                self.showError(String.localize("MSG_ERR_CA_PW_NIL"), animated: true)
                mobileForgotPasswordInputView.passwordConfirmTextField.shouldHighlight(true)
            }
                
            else if (mobileForgotPasswordInputView.passwordConfirmTextField.text != mobileForgotPasswordInputView.passwordTextField.text) {
                self.showError(String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"), animated: true)
                mobileForgotPasswordInputView.passwordConfirmTextField.shouldHighlight(true)
            }
            break
        default:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func selectGeoCountry(_ geoCountry: GeoCountry?) {
        if hasResentSMS {
            hasResentSMS = false
        }
        
        if let country = geoCountry {
            mobileForgotPasswordInputView.signupInputView.codeTextField.text = country.mobileCode
            mobileForgotPasswordInputView.signupInputView.countryTextField.text = country.geoCountryName
        } else {
            mobileForgotPasswordInputView.signupInputView.codeTextField.text = Constants.CountryMobileCode.DEFAULT
            mobileForgotPasswordInputView.signupInputView.countryTextField.text = ""
        }
        self.updateSwipeButton()
    }
    
    func loadGeo() {
        self.showLoading()
        firstly{
            return self.listGeo()
            }.then { _ -> Void in
                self.countryPicker.reloadAllComponents()
                if self.geoCountries.count > 0 {
                    var selectIndex: Int = 0
                    for country in self.geoCountries {
                        if country.mobileCode == Constants.CountryMobileCode.DEFAULT {
                            break
                        }
                        selectIndex += 1
                    }
                    if selectIndex >= self.geoCountries.count {
                        selectIndex = 0
                    }
                    self.selectGeoCountry(self.geoCountries[selectIndex])
                    self.countryPicker.selectedRowInComponent(selectIndex)
                }
                
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func listGeo() -> Promise<Any> {
        return Promise{ fulfill, reject in
            GeoService.storefrontCountries(){
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response!.statusCode == 200 {
                            strongSelf.geoCountries = Mapper<GeoCountry>().mapArray(JSONObject: response.result.value) ?? []
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    @objc func detectCountry() {
        let code = mobileForgotPasswordInputView.signupInputView.codeTextField.text
        for geoCountry : GeoCountry in self.geoCountries {
            if code == geoCountry.mobileCode {
                
                isDetectingCountry = false
                self.updateSwipeButton()
                self.selectGeoCountry(geoCountry)
                return
            }
        }
        isDetectingCountry = false
        self.updateSwipeButton()
        mobileForgotPasswordInputView.signupInputView.countryTextField.text = ""
    }
    
    //MARK: Picker Data Source, Delegate method
    func didClickComplete() {
        self.view.endEditing(true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.geoCountries.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return self.geoCountries[row].geoCountryName + " (\(self.geoCountries[row].mobileCode))"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(self.geoCountries.count > row){
            self.selectGeoCountry(self.geoCountries[row])
        }
    }
    
    //MARK: Login Service
    func login() {
        let username = "\(mobileForgotPasswordInputView.signupInputView.codeTextField.text!)-\(mobileForgotPasswordInputView.signupInputView.mobileNumberTextField.text!)"
        let password = mobileForgotPasswordInputView.passwordTextField.text ?? ""
        LoginManager.login(username, password: password).then { [weak self] (_) -> Void in
            if let strongSelf = self {
                strongSelf.stopLoading()
                strongSelf.view.endEditing(true)
                strongSelf.dismiss(animated: false, completion: {
                    if let loginBlock = strongSelf.loginAfterCompletion {
                        loginBlock()
                    }
                })
            }
            }.catch { (_) in
                self.stopLoading()
                self.navigationController?.popViewController(animated: true)
        }
    }
}


