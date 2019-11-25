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


protocol SelectGeoCountryDelegate: NSObjectProtocol {
    func selectGeoCountry(_ geoCountry: GeoCountry?)
}

protocol MobileSignupViewControllerDelegate: NSObjectProtocol {
    func didUpdateMobile(isSuccess: Bool)
}

class MobileSignupViewController: SignupModeViewController, RequestSMSDelegate, SelectGeoCountryDelegate, UITextFieldDelegate , UIPickerViewDataSource, PickerViewDelegate {
    final let WidthItemBar: CGFloat = 30
    final let HeightItemBar: CGFloat = 25
    final let InputViewMarginLeft: CGFloat = 20
    
    
    
    var signupInputView: SignupInputView!
    var verificationCodeView: VerificationCodeView?
    var mobileVerification = MobileVerification()
    var geoCountries: [GeoCountry] = []
    var isDetectingCountry: Bool = false
//    var swipeSMSView: SwipeSMSView?
    var scrollView = UIScrollView()
    var user = User()
    weak var delegate: MobileSignupViewControllerDelegate?
    var retryAttempt = 0
    var viewMode: SignUpViewMode = .signUp {
        didSet {
            //fix MM-19207
            verificationCodeView?.isShowTNC = (viewMode == .profile) ? false : true
        }
    }
    var countryPicker = CountryPickerView()
    
    func goToInvitationView() {
        let signupInvitationViewController = InvitationSignupViewController()
        signupInvitationViewController.signupMode = self.signupMode
        
        signupInvitationViewController.mobileNumber = self.signupInputView.mobileNumberTextField.text ?? ""
        signupInvitationViewController.mobileCode = self.signupInputView.codeTextField.text ?? ""
        signupInvitationViewController.mobileVerificationId = self.mobileVerification.mobileVerificationId
        signupInvitationViewController.mobileVerficationToken = self.signupInputView.activeCodeTextField.text ?? ""
        signupInvitationViewController.viewMode = self.viewMode
        let navigationController = MmNavigationController(rootViewController: signupInvitationViewController)
        navigationController.modalPresentationStyle = .overFullScreen
        self.present(navigationController, animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.createSubviews()
        self.createBackButton()

        Context.clearInvitationCode()
        switch viewMode {
        case .signUp, .wechat:
            self.title = String.localize("LB_CA_REGISTER")
        case .profile:
            self.title = String.localize("LB_CA_MY_ACCT_MODIFY_MOBILE")
        }
        
        let userId = Context.getUserId()
        countryPicker.delegate = self
        countryPicker.dataSource = self
        if viewMode == .profile && userId != 0 {
            updateUserView()
        } else {
            loadGeo()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(MobileSignupViewController.dismissKeyboard))
        self.scrollView.addGestureRecognizer(tapGesture)
        initAnalyticsViewRecord(
            viewLocation: "MobileVerification",
            viewType: "Signup"
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(MobileSignupViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(MobileSignupViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil);
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func backButtonClicked(_ button: UIButton) {
        let messasge = viewMode == .profile ? String.localize("LB_CA_MOBILE_CHANGE_CANCEL") : String.localize("LB_CA_SIGNUP_CANCEL")
        Alert.alert(self, title: "", message: messasge, okActionComplete: { () -> Void in
            self.navigationController?.popViewController(animated: true)
            }, cancelActionComplete:nil, tintColor: UIColor.secondary2())
    }
  
    func createSubviews() {
        var marginLeft = InputViewMarginLeft
        var height = CGFloat(140)
        if self.signupMode != .profile {
            marginLeft = 0
            height = CGFloat(164)
        }
        signupInputView = RegisterView(frame: CGRect(x: marginLeft, y: 118, width: self.view.bounds.width - marginLeft * 2, height: height))
        scrollView.addSubview(signupInputView)
        signupInputView.hideCountryButton(true)
        signupInputView.countryTextField.delegate = self
        signupInputView.activeCodeTextField.delegate = self
        signupInputView.countryTextField.inputView = self.countryPicker
        signupInputView.delegate = self
        
        let maxY = signupInputView.frame.maxY
        height = CGFloat(0)
        if self.viewMode == .profile {
            height = VerificationCodeView.ConfirmButtonHeight
        }else {
            height = VerificationCodeView.TopMargin * 2 + VerificationCodeView.InviteButtonHeight + VerificationCodeView.ConfirmButtonHeight + VerificationCodeView.CheckBoxViewHeight + 10
        }
        
//        let verificationPostY = signupInputView.frame.maxY ?? 0
        verificationCodeView = VerificationCodeView(frame: CGRect(x: InputViewMarginLeft, y: maxY + 10, width: self.view.bounds.width - InputViewMarginLeft * 2, height: height))
        
        
        verificationCodeView?.viewMode = self.viewMode
        verificationCodeView?.signupMode = self.signupMode
        scrollView.addSubview(verificationCodeView!)
        verificationCodeView?.button.addTarget(self, action: #selector(MobileSignupViewController.checkMobileVerification), for: .touchUpInside)
        verificationCodeView?.button.isEnabled = true //Fix bug MM-18671
        verificationCodeView?.buttonCheckbox.addTarget(self, action: #selector(self.didClickCheckBoxButton), for: UIControlEvents.touchUpInside)
        verificationCodeView?.buttonLink.addTarget(self, action: #selector(self.didClickLinkButton), for: UIControlEvents.touchUpInside)
//
        verificationCodeView?.buttonPrivacy.addTarget(self, action: #selector(self.didClickLinkButton), for: UIControlEvents.touchUpInside)
        verificationCodeView?.inviteButton.addTarget(self, action: #selector(self.checkMobileVerification), for: UIControlEvents.touchUpInside)

		//Fix MM-19207
        verificationCodeView?.isShowTNC = (viewMode == .profile) ? false : true
//
        signupInputView.codeTextField.text = Constants.CountryMobileCode.DEFAULT
        signupInputView.mobileNumberTextField.becomeFirstResponder()
        signupInputView.codeTextField.delegate = self
        signupInputView.mobileNumberTextField.keyboardType = .numberPad
        signupInputView.mobileNumberTextField.delegate = self
        
         signupInputView.mobileNumberTextField.addTarget(self, action: #selector(MobileSignupViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
        
//        verificationCodeView?.textfield.addTarget(self, action: #selector(MobileSignupViewController.textFieldDidChange(_:)), for: UIControlEvents.EditingChanged)
        
         signupInputView.codeTextField.addTarget(self, action: #selector(MobileSignupViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
        
        if let verificationCodeView = self.verificationCodeView {
            scrollView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: verificationCodeView.frame.maxY)
        } else {
            scrollView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 468)
        }
        scrollView.contentSize = self.scrollView.bounds.size
        self.view.addSubview(scrollView)
    }
    
    func updateUserView() {
        firstly {
            return fetchUser()
        }.then { _ -> Void in
            self.loadGeo()
        }
    }
    
    //MARK: SwipeSMSDelegate
    func validatePhoneNumber() -> Bool {
        if let message = self.validatePhoneNumber(signupInputView.mobileNumberTextField.text, countryCode: signupInputView.codeTextField.text)  {
            validateView(true, message: message)
            return false
        }
        return true
        
    }
    func startSMS() {
        
        signupInputView.requestSMSButton.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        signupInputView.requestSMSButton.recordAction(.Tap, sourceRef: "MobileVerification", sourceType: .Button, targetRef: "Code", targetType: .Table)
        
        if let mobileNo = signupInputView.mobileNumberTextField.text, let mobileCode = signupInputView.codeTextField.text {
            //TODO
            Log.debug("startSMS")
//            self.verificationCodeView?.textfield.text = ""
            self.setEnableForInputFields(false)
            firstly {
                return sendMobileVerifcation(mobileNo, mobileCode: mobileCode)
                }.then { _ -> Void in
//                    self.showVerificationView()
                    self.signupInputView.activeCodeTextField.becomeFirstResponder()
                    let bottomOffset = CGPoint(x: 0, y: self.scrollView.contentSize.height + self.scrollView.contentInset.bottom - self.scrollView.bounds.size.height)
                    self.scrollView.setContentOffset(bottomOffset, animated: true)
            }
        }
    }
    
//    func showVerificationView(){
//        self.verificationCodeView?.isHidden = false
//    }
    
    var hasResentSMS = false
    func resetSMS() {
        //TODO
        Log.debug("resetSMS")
        self.setEnableForInputFields(true)
        hasResentSMS = true
    }
    
    func invalidSwipe() {
        if let text =  signupInputView.mobileNumberTextField.text, text.length > 0 {
            
            checkWrongNumberPhone(text)
            
        } else {

            validateView(true, message: String.localize("MSG_ERR_MOBILE_NIL"))
        }
    }
    
    func validateView(_ isHighlight: Bool, message: String? = nil) {
        
        if isHighlight {
            
            showError(message ?? "", animated: true)
            signupInputView.borderTF.isHidden = false
            signupInputView.mobileNumberTextField.becomeFirstResponder()
            
        } else {
            
            signupInputView.borderTF.isHidden = true
        }
    }
    
    func checkWrongNumberPhone(_ text: String) {
        if text.length > 0 {
            guard !(text.length < Constants.MobileNumber.MIN_LENGTH) else {
				
                validateView(true, message: String.localize("MSG_ERR_CA_MOBILE_PATTERN"))
                
                return
            }
            
            
            
            if !text.isNumberic() {
				
                validateView(true, message: String.localize("MSG_ERR_CA_MOBILE_PATTERN"))
				
                return
            }
            if !self.isPhoneValid(text, countryCode: signupInputView.codeTextField.text ?? "") {
				
                validateView(true, message: String.localize("MSG_ERR_CA_MOBILE_PATTERN"))
                return
            }
            
            validateView(false)
        } else {

            validateView(true, message: String.localize("MSG_ERR_MOBILE_NIL"))
            
            
        }
    }
    
    func beginSwipe() {
        
        validateView(false)
        
        self.dismissKeyboard()
        self.setEnableForInputFields(false)
    }
    
    func selectGeoCountry(_ geoCountry: GeoCountry?) {
        if hasResentSMS {
			
            hasResentSMS = false
        }
        if let country = geoCountry {
            signupInputView.codeTextField.text = country.mobileCode
            signupInputView.countryTextField.text = country.geoCountryName
        } else {
            signupInputView.codeTextField.text = Constants.CountryMobileCode.DEFAULT
            signupInputView.countryTextField.text = ""
        }
        self.updateSwipeButton()
    }
    
    func fetchUser() -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.view() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value) ?? User()
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                        strongSelf.showNetWorkErrorAlert(response.result.error)
                    }
                }
            }
        }
    }
    
    override func handleSendMobileVerifcationResponse(_ fulfill: (Any) -> Void, response : DataResponse<Any>, reject : ((Error) -> Void)? = nil){
        if response.result.isSuccess {
            if response.response?.statusCode == 200 {
                if let mobileVerification = Mapper<MobileVerification>().map(JSONObject: response.result.value){
                    self.mobileVerification = mobileVerification
                    
                    signupInputView.borderTF.isHidden = true
                }
                
                fulfill("OK" as Any)
            } else {
//                self.handleError(response, animated: true, reject: reject)
                self.setEnableForInputFields(true)
                signupInputView.borderTF.isHidden = false
                self.signupInputView.resetWithoutCallback()
            }
        } else {
            self.signupInputView.resetWithoutCallback()
            self.setEnableForInputFields(true)
            self.handleError(response, animated: true, reject: reject)
        }
    }
    
    override func handleCheckMobileVerifcationResponse(_ fulfill: (Any) -> Void, response: DataResponse<Any>, reject: ((Error) -> Void)?) {
        if response.result.isSuccess {
            if response.response?.statusCode == 200 {
                self.retryAttempt = 0
                
                
//                if let textField = verificationCodeView?.textfield {
//                    
//                    self.setBorderTextField(textField, isSet: false)
//                }
                
                
                fulfill("OK" as Any)
            } else {
                
                
                // For Non LB_CA_VERCODE_INVALID flow...
                if let resp : ApiResponse = Mapper<ApiResponse>().map(JSONObject: response.result.value){
                    if let appCode = resp.appCode, appCode != "LB_CA_VERCODE_INVALID" {
                        self.showError(String.localize(resp.appCode), animated: true)
                        
                        var statusCode = 0
                        if let code = response.response?.statusCode {
                            statusCode = code
                        }
                        
                        let error = NSError(domain: "", code: statusCode, userInfo: ["AppCode": appCode])
                        reject?(error)
                        
                        self.retryAttempt = 0
                        
                        switch self.viewMode {
                            
                        case .signUp, .wechat:
//                                self.verificationCodeView?.isHidden = true
                            break
                        case .profile:
//                                self.navigationController?.popViewController(animated:true)
                                if resp.appCode == "MSG_ERR_MOBILE_VERIFICATION_ATTEMPT_COUNT_EXCEED" {
                                    self.signupInputView.resetWithoutCallback()
//                                    self.verificationCodeView?.isHidden = true
                                    self.setEnableForInputFields(true)
                                    if self.delegate != nil {
                                        self.delegate?.didUpdateMobile(isSuccess: false)
                                    }
                                }
                        }
                        self.signupInputView?.resetWithoutCallback()
                        self.setEnableForInputFields(true)
                        return
                    }
                }
                
                // For the LB_CA_VERCODE_INVALID Flow....
                
                self.retryAttempt += 1
                
                switch self.viewMode {
                case .signUp, .wechat:
                    if self.retryAttempt >= Constants.Value.MaxAttempt {
                        self.retryAttempt = 0
//                        self.verificationCodeView?.isHidden = true
                        self.showError(String.localize("MSG_ERR_MOBILE_VERIFICATION_ATTEMPT_COUNT_EXCEED"), animated: true)
                    } else {
                        self.showError("\(String.localize("LB_CA_VERCODE_INCORRECT_1"))\(Constants.Value.MaxAttempt - self.retryAttempt)\(String.localize("LB_CA_VERCODE_INCORRECT_2"))", animated: true)
                        
//                        if let textField = verificationCodeView?.textfield {
//                            
//                            self.setBorderTextField(textField, isSet: true)
//                        }
                        
                    }
                case .profile:
                    
                    if self.retryAttempt >= Constants.Value.MaxAttempt {
                        // Reached max. attempt
                        
//                        self.navigationController?.popViewController(animated:true)
                        
//                        if self.delegate != nil {
//                            self.delegate?.didUpdateMobile(isSuccess: false)
//                        }
                        self.signupInputView.resetWithoutCallback()
                        self.setEnableForInputFields(true)
//                        self.verificationCodeView?.isHidden = true
                    } else {
                        self.showError("\(String.localize("LB_CA_VERCODE_INCORRECT_1"))\(Constants.Value.MaxAttempt - self.retryAttempt)\(String.localize("LB_CA_VERCODE_INCORRECT_2"))", animated: true)
                        
//                        if let textField = verificationCodeView?.textfield {
//                            
//                            self.setBorderTextField(textField, isSet: true)
//                        }
                        
                    }
                }
                
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
    
    func setBorderTextField(_ textField: UITextField, isSet: Bool) {
        
        if isSet {
            
            textField.layer.borderColor = UIColor.primary1().cgColor
            
        } else {
            
            textField.layer.borderColor = UIColor.secondary1().cgColor

        }
        textField.layer.borderWidth = 1
        
    }
    
    func updateMobile(mobileCode: String, mobileNumber: String, mobileVerificationId: Int, mobileVerificationToken: String)-> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.updateMobile(mobileCode: mobileCode, mobileNumber: mobileNumber, mobileVerificationId: mobileVerificationId, mobileVerificationToken: mobileVerificationToken) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    @objc func checkMobileVerification(_ button: UIButton){
        
        //Analytic record
        button.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        switch self.viewMode {
        case .signUp:
            if let inviteButton = self.verificationCodeView?.inviteButton, button == inviteButton {
                button.recordAction(.Tap, sourceRef: "InviteCode", sourceType: .Button, targetRef: "InviteCode", targetType: .View)
            } else { //Go to Register Profile
                button.recordAction(.Tap, sourceRef: "MobileVerification-Next", sourceType: .Button, targetRef: "SignupInfo", targetType: .View)
            }
        case .wechat:
            button.recordAction(.Tap, sourceRef: "Submit", sourceType: .Button, targetRef: "Newsfeed-Home-User", targetType: .View)
        default:
            break
        }
        
        if self.isVerificationCodeViewValid() && self.validatePhoneNumber() {
            if let mobileNumber = signupInputView.mobileNumberTextField.text, let mobileCode = signupInputView.codeTextField.text, let mobileVerificationToken = signupInputView.activeCodeTextField.text{
                 let mobileVerificationId:String = String(self.mobileVerification.mobileVerificationId)
                firstly {
                    return checkMobileVerifcation(mobileNumber, mobileCode: mobileCode, mobileVerificationId: mobileVerificationId, mobileVerificationToken: mobileVerificationToken)
                }.then { _ -> Void in
                    
                    //TODO:

                    switch self.viewMode {
                    case .signUp:
                        
                        if let inviteButton = self.verificationCodeView?.inviteButton, button == inviteButton {
                            
                            self.goToInvitationView()
                        } else {
                            self.goToRegisterProfilePage()
                        }

                        break
                    case .wechat:
                            LoginManager.goToStorefront()
                        break
                    case .profile:
                         self.updateMobile(mobileCode: self.signupInputView.codeTextField.text!, mobileNumber: self.signupInputView.mobileNumberTextField.text!, mobileVerificationId: self.mobileVerification.mobileVerificationId, mobileVerificationToken: (self.signupInputView.activeCodeTextField.text)!).then { _ -> Void in
                            
                            self.navigationController?.popViewController(animated:true)
                            
                            if self.delegate != nil {
                                self.delegate?.didUpdateMobile(isSuccess: true)
                            }
                        }
                    
                        break
                    }
                }.catch { (errorType) -> Void in
                        
                }
                
            }
        }
    }
    
    func goToRegisterProfilePage() {
        let mobileSignupProfileViewController = NewMobileSignupProfileViewController()
        mobileSignupProfileViewController.signupMode = self.signupMode
        
        mobileSignupProfileViewController.mobileNumber = self.signupInputView.mobileNumberTextField.text ?? ""
        mobileSignupProfileViewController.mobileCode = self.signupInputView.codeTextField.text ?? ""
        mobileSignupProfileViewController.mobileVerificationId = self.mobileVerification.mobileVerificationId
        mobileSignupProfileViewController.mobileVerficationToken = self.signupInputView.activeCodeTextField.text ?? ""
        self.navigationController?.push(mobileSignupProfileViewController, animated: true)
    }
    
    func loadGeo() {
        self.showLoading()
        firstly {
            return self.listGeo()
        }.then { _ -> Void in
            self.countryPicker.reloadAllComponents()
            if self.geoCountries.count > 0 {
                let geoCountry:GeoCountry?
                if self.viewMode == .profile && self.user.geoCountryId != 0 {
                    geoCountry = self.geoCountries.filter({$0.geoCountryId == self.user.geoCountryId}).first
                } else {
                    geoCountry = self.geoCountries.filter({$0.mobileCode == Constants.CountryMobileCode.DEFAULT}).first
                }
                if let geoCountry = geoCountry{
                    self.selectGeoCountry(geoCountry)
                    let selectedIndex = self.geoCountries.index(where: {$0 === geoCountry}) ?? 0
                    self.countryPicker.selectRow(selectedIndex, inComponent: 0, animated: false)
                }
            }
        }.always {
            self.stopLoading()
        }.catch { [weak self] _ -> Void in
            if let strongSelf = self {
                strongSelf.showAlertCountry()
            }
        }
    }
    
    func showAlertCountry() {
        let alertController = UIAlertController(title: nil, message: String.localize("MSG_ERR_SERVER_ERROR"), preferredStyle: .alert)
        alertController.view.tintColor = UIColor.alertTintColor()
        alertController.addAction(UIAlertAction(title: String.localize("LB_CA_CANCEL"), style: .default, handler: { (action) -> Void in
            
        }))
        
        alertController.addAction(UIAlertAction(title: String.localize("LB_CA_RETRY"), style: .default, handler: { [weak self](action) -> Void in
            if let strongSelf = self {
                strongSelf.loadGeo()
            }
        }))
        
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    func listGeo() -> Promise<Any> {
        return Promise { fulfill, reject in
            GeoService.storefrontCountries() { [weak self] (response) in
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
                    } else {
                        reject(response.result.error!)
                    }
                }
            }
        }
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if hasResentSMS {
           // self.verificationCodeView?.isHidden = true
            hasResentSMS = false
        }
    }
    
    //MARK: UITextFieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        Log.debug("location: \(range.location) string: \(string)")
        if textField.tag == SignupTextFieldTag.verificationCode.rawValue {
            Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateConfirmButton), userInfo: nil, repeats: false)
            return true
        }
        switch textField.tag {
            case SignupTextFieldTag.countryCode.rawValue: //Mobile Code
                if string == "" && range.location == 0 { //Don't allow todelete +
                    return false
                }
                if !isDetectingCountry {
                    isDetectingCountry = true
                    signupInputView.setEnableRequestSMSButton(false, titleColor: nil)
                    Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.detectCountry), userInfo: nil, repeats: false)
                }
                break
            case SignupTextFieldTag.phoneNumber.rawValue: //Mobile number
                 if !signupInputView.isTimerCounting() {
                    Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateSwipeButton), userInfo: nil, repeats: false)
                 }
                break
            case SignupTextFieldTag.countryName.rawValue: //Country name
            return false
            default:
                break
        }
       
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        switch textField.tag {
        case SignupTextFieldTag.verificationCode.rawValue:
            textField.text = ""
            self.updateConfirmButton()
            break
        case SignupTextFieldTag.phoneNumber.rawValue:
            signupInputView.setEnableRequestSMSButton(true, titleColor: nil)
            break
        default:
            break
        }
        return true
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if textField == signupInputView.mobileNumberTextField {
            
            signupInputView.borderTF.isHidden = true
        }
        
//        setBorderTextField(self.signupInputView.activeCodeTextField, isSet: false)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {

    }
    
    
    @objc func detectCountry() {
        
        let code = signupInputView.codeTextField.text
        for geoCountry: GeoCountry in self.geoCountries {
            if code == geoCountry.mobileCode {
                isDetectingCountry = false
                self.updateSwipeButton()
                self.selectGeoCountry(geoCountry)
                return
            }
        }
        isDetectingCountry = false
        self.updateSwipeButton()
        signupInputView.countryTextField.text = ""
    }
    
    @objc func updateSwipeButton() {
        self.updateConfirmButton()
        if isDetectingCountry {
            signupInputView.setEnableRequestSMSButton(false, titleColor: nil)
            return
        }
        if let text = signupInputView.mobileNumberTextField.text {
            if (text.length < Constants.MobileNumber.MIN_LENGTH) {
                signupInputView.setEnableRequestSMSButton(true, titleColor: nil)
                return
            }
            
            if !text.isNumberic() {
                signupInputView.setEnableRequestSMSButton(true, titleColor: nil)
                return
            }
            if !self.isPhoneValid(text, countryCode: signupInputView.codeTextField.text ?? "") {
                signupInputView.setEnableRequestSMSButton(true, titleColor: nil)
                return
            }
            
        }
        
        let countries = self.geoCountries.filter({$0.mobileCode == self.signupInputView.codeTextField.text})
        signupInputView.setEnableRequestSMSButton(countries.count > 0, titleColor: nil)
        
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
        scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: scrollView.contentOffset.y)
    }
    
    @objc func keyboardWillShow(_ sender: Notification) {
 
            if let keyboardFrame = (sender.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
                let keyboardSize = keyboardFrame.cgRectValue.size
                let heightOfset = ((keyboardSize.height + scrollView.contentSize.height + 64) - self.view.bounds.size.height)
                if heightOfset > 0 {
                    let contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: heightOfset, right:  0.0)
                    scrollView.contentInset = contentInset
                    scrollView.scrollIndicatorInsets = contentInset
                }
            }
        
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func setEnableForInputFields(_ isEnable: Bool) {
        signupInputView.countryTextField.isEnabled = isEnable
        //signupInputView.mobileNumberTextField.isEnabled = isEnable
        signupInputView.codeTextField.isEnabled = isEnable
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
        if row < self.geoCountries.count {
            self.selectGeoCountry(self.geoCountries[row])
        }
    }
    
    
    @objc func didClickCheckBoxButton(_ sender: UIButton){
        log.debug("didClickCheckBoxButton")
        self.dismissKeyboard()
        sender.isSelected = !sender.isSelected
        if !sender.isSelected {
            self.showError(String.localize("MSG_ERR_CA_TNC_CONFIRM"), animated: true)
        }
        self.updateConfirmButton()
        
    }
    
    @objc func didClickLinkButton(_ sender: UIButton){
        self.dismissKeyboard()
        log.debug("didClickLinkButton")
        if sender.tag == 0 {
            if let url = ContentURLFactory.urlForContentType(.mmUserAgreement) {
                self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_TNC"), urlGetContentPage: url), animated: true)
            }
        } else {
            if let url = ContentURLFactory.urlForContentType(.mmPrivacyStatement) {
                self.navigationController?.push(AboutDetailViewController(title: String.localize("LB_CA_PRIVACY_POLICY"), urlGetContentPage: url), animated: true)
            }
        }
    }

    @objc func updateConfirmButton () {
        if self.isEnoughInfo(){
            self.verificationCodeView?.enableTouch = true
        } else {
            self.verificationCodeView?.enableTouch = false

        }
    }
    
    func isEnoughInfo() ->Bool {
        if isDetectingCountry {
            return false
        }
        if let text = signupInputView.mobileNumberTextField.text {
            if (text.length < Constants.MobileNumber.MIN_LENGTH) {
                
                return false
            }
            
            if !text.isNumberic() {
                return false
            }
            if !self.isPhoneValid(text, countryCode: signupInputView.codeTextField.text ?? "") {
                return false
            }
            
        }
        
        let countries = self.geoCountries.filter({$0.mobileCode == self.signupInputView.codeTextField.text})
        if countries.count < 0 {
            return false
        }
        if self.signupInputView.activeCodeTextField.text?.length == 0 {
            return false
        }
        
        if let verificationCodeView = self.verificationCodeView {
            if verificationCodeView.isShowTNC && !verificationCodeView.buttonCheckbox.isSelected {
                return false
            }
        }
       
        return true
    }
    
    func isVerificationCodeViewValid() -> Bool{
        if let text = self.signupInputView.activeCodeTextField.text {
            if text.isEmpty {
                self.showError(String.localize("MSG_ERR_CA_MOBILE_VERIFY_NIL"), animated: true)
                return false
            }
        }
        if let verificationCodeView = self.verificationCodeView {
            if verificationCodeView.isShowTNC && !verificationCodeView.buttonCheckbox.isSelected {
                self.showError(String.localize("MSG_ERR_CA_TNC_CONFIRM"), animated: true)
                return false
            }
        }
        return true
    }
    
    // MARK: Invitation code related functions
    
    
    
    
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

}
