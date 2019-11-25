//
//  RequestInvitationCodeViewController.swift
//  merchant-ios
//
//  Created by LongTa on 7/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import PromiseKit
import ObjectMapper
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


class RequestInvitationCodeViewController: MmViewController, UIPickerViewDataSource, PickerViewDelegate{

    let requestInvitationCodeView = RequestInvitationCodeView()
    var countryPicker = CountryPickerView()
    var geoCountries: [GeoCountry] = []
    var selectedCountry:GeoCountry?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_LAUNCH_INVITATION_CODE_GET")
        self.createBackButton()
        self.setupLayout()
        countryPicker.delegate = self
        countryPicker.dataSource = self
        loadGeo()
        initAnalyticLog()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldHaveCollectionView() -> Bool {
        return false
    }
    
    //MARK: Methods
    func setupLayout(){
        requestInvitationCodeView.buttonConfirm.addTarget(self, action: #selector(RequestInvitationCodeViewController.confirm), for: .touchUpInside)
        requestInvitationCodeView.textFieldCountryCode.inputView = self.countryPicker
        requestInvitationCodeView.frame = self.view.bounds
        self.requestInvitationCodeView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard)))
        self.view.addSubview(requestInvitationCodeView)
        
        requestInvitationCodeView.textFieldInvitationName.addTarget(self, action: #selector(RequestInvitationCodeViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
        requestInvitationCodeView.textFieldMobileNo.addTarget(self, action: #selector(RequestInvitationCodeViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
    }
    
    @objc func confirm(_ buttonConfirm: UIButton){
        if isValidData(){
            //call api to get code, after that move to thank page
            self.saveInvite()
        }
        self.recordConfirmButtonAction(buttonConfirm)
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
    
    func loadGeo() {
        self.showLoading()
        firstly {
            return self.listGeo()
            }.then { _ -> Void in
                self.countryPicker.reloadAllComponents()
                if self.geoCountries.count > 0 {
                    self.selectGeoCountry(self.geoCountries[0])
                    self.countryPicker.selectRow(0, inComponent: 0, animated: false)
                }
                
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
        }
    }
    
    func selectGeoCountry(_ geoCountry: GeoCountry?) {
        selectedCountry = geoCountry
        if let selectedCountry = self.selectedCountry{
            if selectedCountry.mobileCode == Constants.CountryMobileCode.HK {
                requestInvitationCodeView.imageViewFlag.image = UIImage(named: "hk")
            } else if selectedCountry.mobileCode == Constants.CountryMobileCode.DEFAULT {
                requestInvitationCodeView.imageViewFlag.image = UIImage(named: "china")
            }
        }
    }
    func showErrorInvitationName(_ message: String) {
        
        self.showError(message, animated: true)
        requestInvitationCodeView.viewInvitationCode.shouldHighlightView(true, cornerRadius: Constants.Button.Radius)
        requestInvitationCodeView.textFieldInvitationName.becomeFirstResponder()
        
    }
    func isValidData() ->Bool{
        
        if requestInvitationCodeView.textFieldInvitationName.text?.length == 0 {
            
            showErrorInvitationName(String.localize("MSG_ERR_FIELD_NIL"))
            return false
        }
        
        requestInvitationCodeView.viewInvitationCode.shouldHighlightView(false, cornerRadius: Constants.Button.Radius)
        
        if requestInvitationCodeView.textFieldMobileNo.text?.length == 0 {
            
            self.showError(String.localize("MSG_ERR_FIELD_NIL"), animated: true)
            requestInvitationCodeView.viewMobileNo.shouldHighlightView(true, cornerRadius: Constants.Button.Radius)
            requestInvitationCodeView.textFieldMobileNo.becomeFirstResponder()

        }
        
        
        
        if let phoneNo = self.mobileNo()
        {
            if let selectedCountry = self.selectedCountry{
                
                if !isPhoneValid(phoneNo, countryCode: selectedCountry.mobileCode){
                    
                    self.showError(String.localize("MSG_ERR_CA_MOBILE_PATTERN"), animated: true)
                    
                    requestInvitationCodeView.viewMobileNo.shouldHighlightView(true, cornerRadius: Constants.Button.Radius)
                    requestInvitationCodeView.textFieldMobileNo.becomeFirstResponder()
                    
                    return false
                }
                
                 requestInvitationCodeView.viewMobileNo.shouldHighlightView(false, cornerRadius: Constants.Button.Radius)
                
            }
            else{
                if !isPhoneValid(phoneNo, countryCode: Constants.CountryMobileCode.DEFAULT){
                    self.showError(String.localize("MSG_ERR_CA_MOBILE_PATTERN"), animated: true)
                    
                    requestInvitationCodeView.viewMobileNo.shouldHighlightView(true, cornerRadius: Constants.Button.Radius)
                    requestInvitationCodeView.textFieldMobileNo.becomeFirstResponder()
                    
                    return false
                }
                requestInvitationCodeView.viewMobileNo.shouldHighlightView(false, cornerRadius: Constants.Button.Radius)
                
            }
        }
        
        return true
    }
    
    func mobileNo() -> String?{
        if let phoneNo = requestInvitationCodeView.textFieldMobileNo.text?.trim(){
            return phoneNo
        }
        return nil
    }
    
    func isPhoneValid(_ phone: String , countryCode: String) -> Bool {
        if countryCode == Constants.CountryMobileCode.HK {
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.MobilePhone.HongKong, text: phone).isEmpty || phone.length != 8 {
                return false
            }
        } else if countryCode == Constants.CountryMobileCode.DEFAULT {
            if RegexManager.matchesForRegexInText(RegexManager.ValidPattern.MobilePhone.China, text: phone).isEmpty || phone.length != 11 {
                return false
            }
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
        if row < self.geoCountries.count {
            self.selectGeoCountry(self.geoCountries[row])
        }
    }
    
    func saveInvite() {
        if let mobileCode = self.selectedCountry?.mobileCode, let mobileNumber = self.mobileNo(), let name = requestInvitationCodeView.textFieldInvitationName.text{
            self.dismissKeyboard()
            self.showLoading()
            firstly {
                return saveInviteService(name, mobileCode: mobileCode, mobileNumber: mobileNumber)
                }.then { _ -> Void in
                    let requestInvitationThankViewController = RequestInvitationThankViewController()
                    requestInvitationThankViewController.selectedCountry = self.selectedCountry
                    requestInvitationThankViewController.mobileNo = self.mobileNo()
                    self.navigationController?.pushViewController(requestInvitationThankViewController, animated: true)
                }.always {
                    self.stopLoading()
                }.catch { _ -> Void in
                    Log.error("error")
            }
        }
    }
    
    func saveInviteService(_ name: String, mobileCode: String, mobileNumber: String) -> Promise<Any> {
        return Promise{ fulfill, reject in
            InviteService.saveInviteRequest(name, mobileCode: mobileCode, mobileNumber: mobileNumber, completion: {
                [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                        } else {
                            strongSelf.handleError(response, animated: true, reject: reject)
                        }
                    }
                    else{
                        reject(response.result.error!)
                    }
                }
                })
        }
    }
    
    @objc func dismissKeyboard(){
        self.view.endEditing(true)
    }
    
    // MARK: Logging
    func initAnalyticLog(){
        initAnalyticsViewRecord(
            nil,
            authorType: nil,
            brandCode: nil,
            merchantCode: nil,
            referrerRef: nil,
            referrerType: nil,
            viewDisplayName: "User: \(Context.getUserProfile().displayName)",
            viewParameters: Context.getUserProfile().userKey,
            viewLocation: "GetInvitationCode",
            viewRef: nil,
            viewType: "ExclusiveLaunch"
        )
    }
    
    func recordTextField(_ textField: UITextField){
        if let text = textField.text?.trim(), textField.text?.trim().length > 0{
            var sourceRef = ""
            var targetRef = ""
            switch textField {
            case self.requestInvitationCodeView.textFieldInvitationName:
                sourceRef = "Name"
                targetRef = text
                break
            case self.requestInvitationCodeView.textFieldMobileNo, self.requestInvitationCodeView.textFieldCountryCode:
                sourceRef = "Mobile"
                targetRef = (self.selectedCountry?.mobileCode ?? "").trim() + " " + text
                break
            default:
                break
            }
            textField.recordAction(
                .Input,
                sourceRef: sourceRef,
                sourceType: .Text,
                targetRef: targetRef,
                targetType: .GetInvitationCode
            )
        }
    }
    
    func recordConfirmButtonAction(_ buttonConfirm: UIButton){
        //record text field input first
        self.recordTextField(self.requestInvitationCodeView.textFieldInvitationName)
        self.recordTextField(self.requestInvitationCodeView.textFieldMobileNo)
        
        //record button action
        buttonConfirm.recordAction(
            .Tap,
            sourceRef: "Submit",
            sourceType: .Button,
            targetRef: "GetInvitationCodeThanks",
            targetType: .View
        )
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        if let parentView = textField.superview {
            
            parentView.setStyleNoNormal()
        }
        
    }
}
