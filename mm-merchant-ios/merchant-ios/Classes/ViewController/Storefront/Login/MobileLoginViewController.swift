//
//  MobileLoginViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 29/1/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import ObjectMapper
import PromiseKit
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

protocol MobileLoginDelegate: NSObjectProtocol{
    func forgotPasswordClicked(_ message: String?)
    func didDismissLogin()
}

class MobileLoginViewController :  SignupModeViewController, SelectGeoCountryDelegate, UITextFieldDelegate, UIPickerViewDataSource, PickerViewDelegate {
    
    private var blurEffectView = UIView()
    var mobileLoginView = MobileLoginView()
    
    var ContentViewHeight : CGFloat = 280
    private let ExpandedContentViewHeight : CGFloat = 355
    var geoCountries : [GeoCountry] = []
    var isDetectingCountry : Bool = false
    var isCodeInput = false
    weak var mobileLoginDelegate : MobileLoginDelegate?
    private var countryPicker = CountryPickerView()
    
    var privateUser = User()
    
    var isDisappear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        countryPicker.delegate = self
        countryPicker.dataSource = self
        setupLayout()
       
        mobileLoginView.button.addTarget(self, action: #selector(login(_:)), for: .touchUpInside)
        mobileLoginView.cornerButton.addTarget(self, action: #selector(MobileLoginViewController.forgotPassword), for: .touchUpInside)
        mobileLoginView.upperTextField.delegate = self
        mobileLoginView.lowerTextField.delegate = self
       
        loadGeo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.3, animations: { () -> Void in
            self.mobileLoginView.frame =  CGRect(x: 0, y: self.view.frame.maxY - self.mobileLoginView.bounds.height, width: self.mobileLoginView.bounds.width, height: self.mobileLoginView.bounds.height)
        }) 
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(MobileLoginViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MobileLoginViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
        
        isDisappear = true
        self.dismissKeyboard()
        
    }
    //MARK: KeyboardWilShow/Hide callback
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.mobileLoginView.frame =  CGRect(x: 0, y: self.view.frame.maxY - self.mobileLoginView.bounds.height - keyboardSize.height, width: self.mobileLoginView.bounds.width, height: self.mobileLoginView.bounds.height)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        self.mobileLoginView.frame =  CGRect(x: 0, y: self.view.frame.maxY - self.mobileLoginView.bounds.height, width: self.mobileLoginView.bounds.width, height: self.mobileLoginView.bounds.height)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    //MARK: Set up Layout on viewDidLoad
    
    func setupLayout(){
        self.title = String.localize("LB_DETAILS")
        self.navigationItem.titleView = UIImageView(image: UIImage(named: "logo_demo_L"))
        mobileLoginView.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: ContentViewHeight)
        mobileLoginView.backgroundColor = UIColor.white
        view.addSubview(mobileLoginView)
        mobileLoginView.upperTextField.placeholder = String.localize("LB_CA_MOB_UN_EMAIL")
        mobileLoginView.lowerTextField.placeholder = String.localize("LB_ENTER_PW")
        mobileLoginView.button.setTitle(String.localize("LB_CA_LOGIN"), for: UIControlState())
        mobileLoginView.cornerButton.setTitle(String.localize("LB_CA_FORGOT_PASSWORD"), for: UIControlState())
        mobileLoginView.isUserInteractionEnabled = true
        mobileLoginView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(MobileLoginViewController.tapOnLoginView)))
        mobileLoginView.hideCodeInput()
        self.blurEffectView.frame = self.view.bounds
        self.blurEffectView.backgroundColor = UIColor.clear
        self.blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.insertSubview(self.blurEffectView, belowSubview: mobileLoginView)
       
        self.view.backgroundColor = UIColor.clear
    }
    
    @objc func tapOnLoginView() {
        Log.debug("tapOnLoginView")
        dismissKeyboard()
    }
    
    @objc func dismiss() {
        dismissKeyboard()
        
        UIView.animate(
            withDuration: 0.3,
            animations: { () -> Void in
                self.mobileLoginView.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: self.ContentViewHeight)
            }, completion: { (success) -> Void in
                self.mobileLoginDelegate?.didDismissLogin()
                self.dismiss(animated: false, completion: nil)
            }
        )
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    //MARK: Forgot Password Service
    @objc func forgotPassword(_ sender: UIButton){
        dismissKeyboard()

        UIView.animate(
            withDuration: 0.3,
            animations: { () -> Void in
                self.mobileLoginView.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: self.ContentViewHeight)
            },
            completion: { (success) -> Void in
                self.dismiss(animated: false) { () -> Void in
                    if self.mobileLoginDelegate != nil {
                        self.mobileLoginDelegate?.forgotPasswordClicked(nil)
                    }
                }
            }
        )
    }
    
    func getProfile() {
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            UserService.fetchUser(true).then { (user) -> Void in
                self.privateUser = user
            }
            DispatchQueue.main.async(execute: { () -> Void in
                
            })
        })
    }
    
    @objc func login(_ sender: UIButton){
        self.login(sender, blockAfterLogin: nil)
    }
    
    //MARK: Login Service
    @objc func login(_ sender:UIButton, blockAfterLogin : AnalyticsManager.AnalyticBlockForLoginCompleted?){}

    func isValidLoginInfo() -> Bool{
        if self.isValidData() {
            if self.validateUserNameField() {
                return self.validatePasswordField()
            }
        }
        return false
    }
    
    func styleValidateAccount(_ isValid: Bool, message: String? = nil) {
        if isValid {
            self.showError(message ?? "", animated: true)
            mobileLoginView.upperTextField.becomeFirstResponder()
            mobileLoginView.borderUpperTF.isHidden = false
        } else {
            mobileLoginView.borderUpperTF.isHidden = true
        }
    }
    
    func styleValidatePassword(_ isValid: Bool, message: String? = nil) {
        if isValid {
            self.showError(message ?? "", animated: true)
            mobileLoginView.lowerTextField.becomeFirstResponder()
            mobileLoginView.borderLowerTF.isHidden = false
        } else {
            mobileLoginView.borderLowerTF.isHidden = true
        }
    }
    
    func isValidData() ->Bool{
        if mobileLoginView.upperTextField.text?.trim().length == 0 {
            styleValidateAccount(true, message: String.localize("MSG_ERR_CA_USERNAME_NIL"))
            mobileLoginView.upperTextField.text = ""
            return false
        } else if mobileLoginView.upperTextField.text?.trim().length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Username, text: mobileLoginView.upperTextField.text?.trim()).isEmpty && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.SpecialCharacter, text: mobileLoginView.upperTextField.text?.trim()).isEmpty && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Email, text: mobileLoginView.upperTextField.text?.trim()).isEmpty{}
        
        styleValidateAccount(false)
        if mobileLoginView.lowerTextField.text?.length == 0 {
            styleValidatePassword(true, message: String.localize("MSG_ERR_CA_PW_NIL"))
            return false
        }
        styleValidatePassword(false)
        return true
    }
    
    func validateUserNameField() ->Bool{
        if mobileLoginView.upperTextField.text?.trim().length == 0 {
            styleValidateAccount(true, message: String.localize("MSG_ERR_CA_USERNAME_NIL"))
            mobileLoginView.upperTextField.text = ""
            
            return false
        } else if mobileLoginView.upperTextField.text?.trim().length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Username, text: mobileLoginView.upperTextField.text?.trim()).isEmpty && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.SpecialCharacter, text: mobileLoginView.upperTextField.text?.trim()).isEmpty && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Email, text: mobileLoginView.upperTextField.text?.trim()).isEmpty{
            styleValidateAccount(true, message: String.localize("MSG_ERR_CA_ACCOUNT_PATTERN"))
            return false
        }
        
        styleValidateAccount(false)
        return true
    }
    
    func validatePasswordField() ->Bool{
        if mobileLoginView.lowerTextField.text?.length == 0 {
            styleValidatePassword(true, message: String.localize("MSG_ERR_CA_PW_NIL"))
            return false
        }

        styleValidatePassword(false)
        return true
    }
    
    func showCodeInput(){
        mobileLoginView.frame = CGRect(x: self.mobileLoginView.frame.minX, y: self.mobileLoginView.frame.minY - ExpandedContentViewHeight + ContentViewHeight, width: self.mobileLoginView.frame.width, height: ExpandedContentViewHeight)
        mobileLoginView.showCodeInput()
        mobileLoginView.signupInputView.hideCountryButton(true)
        mobileLoginView.signupInputView.countryTextField.inputView = self.countryPicker
        mobileLoginView.signupInputView.countryTextField.delegate = self
        mobileLoginView.signupInputView.codeTextField.text = Constants.CountryMobileCode.DEFAULT
        mobileLoginView.signupInputView.mobileNumberTextField.becomeFirstResponder()
        mobileLoginView.signupInputView.codeTextField.delegate = self
        mobileLoginView.signupInputView.mobileNumberTextField.delegate = self
        mobileLoginView.signupInputView.requestSMSButton.isHidden = true
        mobileLoginView.signupInputView.activeCodeTextField.isHidden = true
        isCodeInput = true
        
    }

    func selectGeoCountry(_ geoCountry: GeoCountry?) {
        if let country = geoCountry {
            mobileLoginView.signupInputView.codeTextField.text = country.mobileCode
            mobileLoginView.signupInputView.countryTextField.text = country.geoCountryName
        } else {
            mobileLoginView.signupInputView.codeTextField.text = Constants.CountryMobileCode.DEFAULT
            mobileLoginView.signupInputView.countryTextField.text = ""
        }
    }
    
    //MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == mobileLoginView.upperTextField {
            mobileLoginView.lowerTextField.becomeFirstResponder()
        }else if textField == mobileLoginView.lowerTextField {
            self.login(mobileLoginView.button, blockAfterLogin: nil)
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textFieldTag = SignupTextFieldTag(rawValue: textField.tag) {
            switch  textFieldTag {
            case .countryCode: //Mobile Code
                if string == "" && range.location == 0 { //Don't allow todelete +
                    return false
                }
                if !isDetectingCountry {
                    isDetectingCountry = true
                    Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(MobileLoginViewController.detectCountry), userInfo: nil, repeats: false)
                }
                break
            case .countryName: //Country name
                return false
            default:
                break
            }
        }
        return true
    }
    
    @objc func detectCountry() {
        let code = mobileLoginView.signupInputView.codeTextField.text
        for geoCountry : GeoCountry in self.geoCountries {
            if code == geoCountry.mobileCode {
                mobileLoginView.signupInputView.countryButton.setTitle(geoCountry.geoCountryName, for: UIControlState())
                isDetectingCountry = false
                return
            }
        }
        isDetectingCountry = false
        mobileLoginView.signupInputView.countryButton.setTitle(String.localize("LB_COUNTRY_PICK"), for: UIControlState())
    }
    
    func loadGeo() {
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
                        if response.response?.statusCode == 200 {
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
                    }
                    else{
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    //MARK: UITextFieldDelegate
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if textField.tag == MobileLoginViewTextfieldTag.lowerTextFieldTag.rawValue {
            //Fix MM-6759 The password should not show as big dot
            textField.isSecureTextEntry = false
            textField.isSecureTextEntry = true
        }
        return true
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
        if geoCountries.count > row {
            self.selectGeoCountry(self.geoCountries[row])
        }
    }
}
