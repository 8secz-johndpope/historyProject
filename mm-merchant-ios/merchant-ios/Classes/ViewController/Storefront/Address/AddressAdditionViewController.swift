//
//  AddressAdditionViewController.swift
//  merchant-ios
//
//  Created by hungvo on 2/19/16.
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


struct GeoRecord {
    var geoCountryId = 0
    var geoProvinceId = 0
    var geoCityId = 0
}



class AddressAdditionViewController: SignupModeViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UITextViewDelegate {
    
    enum Mode: Int {
        case add = 0,
        change
    }

    enum IndexPathRow: Int {
        case receiverName = 0,
        country,
        phoneCode,
        phoneNumber,
        address,
        streetAddress,
        postalZip
    }
    
    private final let AddressAdditionCellID = "AddressAdditionCellID"
    private final let DefaultCellID = "DefaultCellID"
    private final let HeaderViewHeight = CGFloat(25)
    private final let DefaultCellHeight = CGFloat(46)
    private final let AddressCellHeight = CGFloat(60)
    private final let PhoneCodeCellWidth = CGFloat(120)
    private final let ConfirmViewHeight = CGFloat(61)
    private final let InputViewHeight = CGFloat(206)

    private let titleHeaderPaddingTop = CGFloat(3)
    
    var activeTextField: UITextField?
    var activeTextView: UITextView?
    var disableBackButton = false
    var continueCheckoutProcess = false
    var didAddAddress: ((Address) -> ())?
    
    var arrayTextFieldValids = [Int]()
    
    //TODO: dummy data - need to modify
    private let placeholders = [
        String.localize("LB_CA_RECEIVER_NAME"),
        String.localize("LB_SELECT_COUNTRY"),
        String.localize(""),
        String.localize("LB_CA_INPUT_MOBILE"),
        String.localize("LB_CA_ADDR_PICKER_PLACEHOLDER"),
        String.localize("LB_CA_DETAIL_STREET_ADDR"),
        String.localize("LB_POSTAL_OR_ZIP")
    ]
    
    var countryTextField: UITextField?
    var countryInputView: AddressInputView!
    var countryPicker: UIPickerView!
    var countryPickerDataSource = Array<GeoCountry> ()
    var geoCountrySelected: GeoCountry?
    
    var provinceAndCityTextField: UITextField?
    var provinceAndCityInputView: AddressInputView!
    var provinceAndCityPicker: UIPickerView!
    
    private var geoProvinces = [GeoProvince]()
    private var geoCities = [GeoCity]()
    
    var geoProvinceSelected: GeoProvince?
    var geoCitySelected: GeoCity?
    
    var phoneCodeTextField: UITextField?
    
    var geoRecords: [GeoRecord] = []
    
    var addressCell: AddressAdditionCell!
    
    var address = Address()
    
    var currentAddressAdditionMode: Mode = .add
    
    var receiverNameTextField: UITextField!
    var phoneNumberTextField: UITextField!
    var streetAddressTextView: MMPlaceholderTextView!
    var postalCodeTextField : UITextField!
    var provinceTextField: UITextField!
    var arrowCountryAndProvice: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController!.isNavigationBarHidden = false
        
        if currentAddressAdditionMode == .change {
            self.title = String.localize("LB_CA_EDIT_SHIPPING_ADDR")
            
            var geoRecord = GeoRecord()
            geoRecord.geoCountryId = address.geoCountryId
            geoRecord.geoProvinceId = address.geoProvinceId
            geoRecord.geoCityId = address.geoCityId
            
            geoRecords.append(geoRecord)
        } else {
            self.title = String.localize("LB_CA_NEW_SHIPPING_ADDR")
        }
        
        setupNavigationBar()
        setupDismissKeyboardGesture()
        
        let headerView = { () -> UIView in
            let view = UIView(frame: CGRect(x: 0, y: self.collectionView.frame.origin.y, width: self.view.bounds.width, height: HeaderViewHeight))
            view.backgroundColor = UIColor.backgroundGray()
            
            let titleHeader = UILabel(frame: CGRect(x: 0, y: titleHeaderPaddingTop, width: self.view.bounds.width, height: HeaderViewHeight - titleHeaderPaddingTop))
            titleHeader.text = String.localize("LB_CA_SHIPPING_ADDR")
            titleHeader.formatSize(12)
            titleHeader.textColor = UIColor.secondary2()
            titleHeader.textAlignment = .center
            view.addSubview(titleHeader)
            
            return view
        } ()
        
        self.view.addSubview(headerView)
        
		self.createRightButton(continueCheckoutProcess ? String.localize("LB_CA_SAVE_N_CHECKOUT") : String.localize("LB_CA_SAVE"), action:  #selector(AddressAdditionViewController.confirm))
        
        self.collectionView.frame = CGRect(x: self.collectionView.frame.origin.x, y: self.collectionView.frame.origin.y + HeaderViewHeight, width: self.collectionView.frame.width, height: self.collectionView.frame.height - Constants.BottomButtonContainer.Height)
        
        self.collectionView.setCollectionViewLayout(UICollectionViewFlowLayout(), animated: true)
        self.collectionView!.register(AddressAdditionCell.self, forCellWithReuseIdentifier: AddressAdditionCellID)
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: DefaultCellID)
        
        countryInputView = AddressInputView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: InputViewHeight))
        countryInputView.pickerView.delegate = self
        countryInputView.pickerView.dataSource = self
        countryInputView.doneButtonTappedHandler = { [weak self] in
            if let strongSelf = self {
                strongSelf.view.endEditing(true)
            }

        }
        countryPicker = countryInputView.pickerView
        
        provinceAndCityInputView = AddressInputView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: InputViewHeight))
        provinceAndCityInputView.pickerView.delegate = self
        provinceAndCityInputView.pickerView.dataSource = self
        provinceAndCityInputView.doneButtonTappedHandler = { [weak self] in
            if let strongSelf = self {
                strongSelf.view.endEditing(true)
            }

        }
        provinceAndCityPicker = provinceAndCityInputView.pickerView
        
        if address.phoneCode == "" {
            address.phoneCode = Constants.CountryMobileCode.DEFAULT
        }
        
        self.showLoading()
        
        firstly {
            return self.listGeoCountry()
        }.then { _ -> Void in
            self.selectCountryInPicker(withPhoneCode: self.address.phoneCode, selectRow: true)
            self.collectionView.reloadData()
        }.always {
            self.stopLoading()
        }.catch { _ -> Void in
            Log.error("error")
        }
        
        if self.signupMode == .checkout {
            switch currentAddressAdditionMode {
            case .add:
                self.initAnalyticsViewRecord(viewDisplayName: "UserAddress-Add", viewLocation: "UserAddress-Add", viewType: "Checkout")
            case .change:
                self.initAnalyticsViewRecord(viewDisplayName: "UserAddress-Edit", viewLocation: "UserAddress-Edit", viewType: "Checkout")
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func setupNavigationBar() {
        var showBackButton = false
        
        switch signupMode {
        case .normal, .profile:
            showBackButton = true
        case .checkout, .checkoutSwipeToPay:
            showBackButton = !disableBackButton
        default:
            break
        }
        
        if showBackButton {
            let buttonBack = UIButton(type: .custom)
            buttonBack.setImage(UIImage(named: "back_grey"), for: UIControlState())
            buttonBack.frame = CGRect(x: 0, y: 0, width: Constants.Value.BackButtonWidth, height: Constants.Value.BackButtonHeight)
            buttonBack.contentEdgeInsets = UIEdgeInsets.init(top: 0, left: Constants.Value.BackButtonMarginLeft, bottom: 0, right: 0)
            buttonBack.addTarget(self, action: #selector(AddressAdditionViewController.backButtonTapped), for: .touchUpInside)
            
            let leftBarButtonItem = UIBarButtonItem(customView: buttonBack)
            
            self.navigationItem.leftBarButtonItem = leftBarButtonItem
            self.navigationItem.hidesBackButton = false
        } else {
            self.navigationItem.leftBarButtonItem = nil
            self.navigationItem.hidesBackButton = true
        }
    }
    
    //MARK: Action handler
    
    @objc func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    func highLightTextField(_ textField: UITextField, message: String)  {
        
        showError(message, animated: true)
        textField.shouldHighlight(true, isAddBorderView: true)
        textField.becomeFirstResponder()
    }
    
    @objc func confirm(_ button: UIButton) {
        button.initAnalytics(withViewKey: analyticsViewRecord.viewKey)
        button.recordAction(.Edit, sourceRef: address.userAddressKey, sourceType: .UserAddress, targetRef: "UserAddress-Select", targetType: .View)
        
        arrayTextFieldValids.removeAll()
        
        guard !(address.recipientName.length < 1) else {
//            self.showError(String.localize("MSG_ERR_CA_RECEIVER_NIL"), animated: true)
            self.highLightTextField(receiverNameTextField, message: String.localize("MSG_ERR_CA_RECEIVER_NIL"))
            return
            
        }
        receiverNameTextField.shouldHighlight(false)
        arrayTextFieldValids.append(receiverNameTextField.tag)
        
        guard address.geoCountryId != 0 else {
            self.showError(String.localize("MSG_ERR_LOCATION_COUNTRY"), animated: true)
            return
        }
        
        guard !(address.phoneCode.length < 1) else {
            self.showError(String.localize("MSG_ERR_CA_ACCOUNT_NIL"), animated: true) //"Missing phone code"
            return
        }
        
        guard !(address.phoneNumber.length < 1) else {
//            self.showError(String.localize("MSG_ERR_MOBILE_NIL"), animated: true)
            self.highLightTextField(phoneNumberTextField, message: String.localize("MSG_ERR_MOBILE_NIL"))
            return
        }
        
        
        guard isValidPhone(address.phoneNumber, countryCode: address.phoneCode) else {
//            self.showError(String.localize("MSG_ERR_CA_MOBILE_PATTERN"), animated: true)
            self.highLightTextField(phoneNumberTextField, message: String.localize("MSG_ERR_CA_MOBILE_PATTERN"))
            return
        }
        phoneNumberTextField.shouldHighlight(false)
        arrayTextFieldValids.append(phoneNumberTextField.tag)
        
        if let provinceTextField = provinceAndCityTextField {
            guard address.geoProvinceId != 0 else {
                //            self.showError(String.localize("MSG_ERR_CA_SHIP_ADDR_PROV_CITY_NIL"), animated: true)
                self.highLightTextField(provinceTextField, message: String.localize("MSG_ERR_CA_SHIP_ADDR_PROV_CITY_NIL"))
                
                return
            }
            
            guard address.geoCityId != 0 else {
//                self.showError(String.localize("MSG_ERR_CA_SHIP_ADDR_PROV_CITY_NIL"), animated: true)
                self.highLightTextField(provinceTextField, message: String.localize("MSG_ERR_CA_SHIP_ADDR_PROV_CITY_NIL"))
                arrowCountryAndProvice.isHidden = false
                return
            }
            
            provinceTextField.shouldHighlight(false, isAddBorderView: true)
            arrowCountryAndProvice.isHidden = true
            arrayTextFieldValids.append(provinceTextField.tag)
            

        }
        
        
        
        
        
        guard !(self.addressCell.textView.text?.length < 1) else {
            self.showError(String.localize("MSG_ERR_CA_DETAIL_SHIP_ADDR_NIL"), animated: true)
            streetAddressTextView.shouldHighlight(true)
            streetAddressTextView.becomeFirstResponder()
            
            return
        }
        
        streetAddressTextView.shouldHighlight(false)
		
		address.address = streetAddressTextView.text
        
//        if address.phoneCode == Constants.CountryMobileCode.DEFAULT {

//            guard !(address.postalCode.length < 1) else {
//                self.showError(String.localize("MSG_ERR_CA_POSTAL_CODE_NIL"), animated: true)
//                return
//            }

//        }
		
        if address.postalCode.length > 0 {
            
            guard isValidPostalCode(address.postalCode, countryCode: address.phoneCode) else {
//                self.showError(String.localize("MSG_ERR_CA_POSTAL_PATTERN"), animated: true)
                self.highLightTextField(postalCodeTextField, message: String.localize("MSG_ERR_CA_POSTAL_PATTERN"))
                return
            }
            postalCodeTextField.shouldHighlight(false)
            arrayTextFieldValids.append(postalCodeTextField.tag)
        }
        
        
        address.isDefault = true
        
        self.showLoading()
        
        if self.currentAddressAdditionMode == .change {
            if self.signupMode == .checkout {
                self.view.recordAction(.Edit, sourceRef: address.userAddressKey, sourceType: .UserAddress, targetRef: "UserAddress-Select", targetType: .View)
            }
            
            firstly {
                return self.changeAddress(address)
            }.then { [weak self] _ -> Void in
                if let strongSelf = self{
                    if let navViewController = strongSelf.navigationController {
                        navViewController.popViewController(animated:true)
                    }
                }
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
            }
        } else {
            
            //Analytics for checkout page
            if self.signupMode == .checkout {
                self.view.recordAction(.Tap, sourceRef: "Confirm", sourceType: .Button, targetRef: "Checkout", targetType: .View)
                self.view.recordAction(.Add, sourceRef: "\(address.country)-\(address.province)-\(address.city)", sourceType: .UserAddress, targetRef: "Checkout", targetType: .View)
            }
            
            firstly {
                return self.saveNewAddress(address)
            }.then { _ -> Void in
                if self.currentAddressAdditionMode == .change {
                    if let navViewController = self.navigationController {
                        navViewController.popViewController(animated:true)
                    }
                } else {
                    if let didAddAddress = self.didAddAddress {
                        didAddAddress(self.address)
                    }
                    
                    if self.signupMode == .checkout {
                        self.showSuccessPopupWithText(String.localize("LB_CA_ADD_ADDR_SUC"))
                        
                        if let navigationController = self.navigationController {
                            for viewController in navigationController.viewControllers {
                                if let checkoutViewController = viewController as? FCheckoutViewController {
                                    navigationController.popToViewController(checkoutViewController, animated: true)
                                    break
                                }
                            }
                        }
                    } else if self.signupMode == .checkoutSwipeToPay {
                        self.showSuccessPopupWithText(String.localize("LB_CA_ADD_ADDR_SUC"))
                        
                        if let navigationController = self.navigationController {
                            for viewController in navigationController.viewControllers {
                                if let checkoutViewController = viewController as? FCheckoutViewController {
                                    navigationController.popToViewController(checkoutViewController, animated: true)
                                    break
                                }
                            }
                        }
                    } else if self.signupMode == .profile {
                        if let navViewController = self.navigationController {
                            self.showSuccessPopupWithText(String.localize("LB_CA_ADD_ADDR_SUC"))
                            navViewController.popViewController(animated:true)
                        }
                    }
                }
            }.always {
                self.stopLoading()
            }.catch { _ -> Void in
                Log.error("error")
            }
        }
    }
    
    func listGeoCountry(completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            _ = GeoService.storefrontCountries({ [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let countries: Array<GeoCountry> = Mapper<GeoCountry>().mapArray(JSONObject: response.result.value)!
                            strongSelf.countryPickerDataSource = countries
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else{
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    func listGeoProvince(_ geoCountryId: Int, completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            _ = GeoService.storefrontProvinces(geoCountryId, completion:{ [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let geoProvinces = Mapper<GeoProvince>().mapArray(JSONObject: response.result.value) {
                                strongSelf.geoProvinces = geoProvinces
                                strongSelf.provinceAndCityPicker.reloadAllComponents()
                                
                                var index = 0
                                var recordFound = false
                                
                                for geoProvince in geoProvinces {
                                    if geoProvince.geoId == strongSelf.address.geoProvinceId {
                                        strongSelf.geoProvinceSelected = geoProvince
                                        strongSelf.provinceAndCityPicker.selectRow(index, inComponent: 0, animated: true)
                                        recordFound = true
                                        break
                                    }
                                    index = index + 1
                                }
                                
                                if !recordFound {
                                    strongSelf.geoProvinceSelected = geoProvinces[0]
                                    strongSelf.provinceAndCityPicker.selectRow(0, inComponent: 0, animated: true)
                                }
                            }
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
            })
        }
    }
    
    func listGeoCity(_ geoProvinceId: Int, completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            _ = GeoService.storefrontCities(geoProvinceId, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let geoCities = Mapper<GeoCity>().mapArray(JSONObject: response.result.value) {
                                strongSelf.geoCities = geoCities
                                
                                var index = 0
                                var recordFound = false
                                
                                for geoCity in geoCities {
                                    if geoCity.geoId == strongSelf.address.geoCityId {
                                        strongSelf.geoCitySelected = geoCity
                                        strongSelf.provinceAndCityPicker.selectRow(index, inComponent: 1, animated: true)
                                        recordFound = true
                                        break
                                    }
                                    
                                    index = index + 1
                                }
                                
                                if !recordFound {
                                    strongSelf.geoCitySelected = geoCities[0]
                                    strongSelf.provinceAndCityPicker.selectRow(0, inComponent: 1, animated: true)
                                }
                                
                                strongSelf.provinceAndCityPicker.reloadAllComponents()
                            }
                            
                            fulfill("OK")
                        } else {
                            var statusCode = 0
                            if let code = response.response?.statusCode {
                                statusCode = code
                            }
                            let error = NSError(domain: "", code: statusCode, userInfo: nil)
                            reject(error)
                        }
                    } else{
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    func saveNewAddress(_ address: Address, completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            _ = AddressService.save(address, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let address = Mapper<Address>().map(JSONObject: response.result.value) {
                                strongSelf.address = address
                            }
                            
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
            })
        }
    }
    
    func changeAddress(_ address: Address, completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            _ = AddressService.change(address, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let address = Mapper<Address>().map(JSONObject: response.result.value) {
                                strongSelf.address = address
                            }
                            
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
            })
        }
    }
    
    func reloadProvinceAndCity(geoCountryId: Int, updateGeoContent: Bool = false) {
        firstly {
            return self.listGeoProvince(geoCountryId)
        }.then { _ -> Void in
            
            if self.geoProvinceSelected != nil {
                firstly {
                    return self.listGeoCity(self.geoProvinceSelected!.geoId)
                    }.then { _ -> Void in
                        if updateGeoContent {
                            self.updateGeoContent()
                        }
                    }.catch { _ -> Void in
                        Log.error("error")
                }
            }
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    func selectCountryInPicker(withPhoneCode phoneCode: String, selectRow: Bool) {
        countryPicker.reloadAllComponents()
        
        var countryFound = false
        
        for i in 0..<countryPickerDataSource.count {
            let country = countryPickerDataSource[i]
            
            if country.mobileCode == phoneCode {
                countryFound = true
                
                if selectRow {
                    countryPicker.selectRow(i, inComponent: 0, animated: false)
                }
                
                if phoneCodeTextField != nil && phoneCodeTextField?.tag == IndexPathRow.phoneCode.rawValue {
                    phoneCodeTextField?.text = phoneCode
                }
                
                geoCountrySelected = country
                
                address.phoneCode = phoneCode
                address.country = country.geoCountryName
                address.geoCountryId = country.geoCountryId
                
                countryTextField?.text = address.country
                
                address.geoProvinceId = 0
                address.geoCityId = 0
                
                geoProvinceSelected = nil
                geoCitySelected = nil
                
                for geoRecord in geoRecords {
                    if geoRecord.geoCountryId == address.geoCountryId {
                        address.geoProvinceId = geoRecord.geoProvinceId
                        address.geoCityId = geoRecord.geoCityId
                        break
                    }
                }
                
                var updateGeoContent = true
                
                if address.geoProvinceId == 0 && address.geoCityId == 0 {
                    provinceAndCityTextField?.text = ""
                    updateGeoContent = false
                }
                
                if let geoCountry = geoCountrySelected {
                    reloadProvinceAndCity(geoCountryId: geoCountry.geoCountryId, updateGeoContent: updateGeoContent)
                }
            }
        }
        
        if !countryFound {
            if phoneCodeTextField != nil && phoneCodeTextField?.tag == IndexPathRow.phoneCode.rawValue {
                phoneCodeTextField?.text = address.phoneCode
            }
        }
    }
    
    func updateGeoContent() {
        if geoProvinceSelected != nil {
            address.province = geoProvinceSelected!.geoName
            address.geoProvinceId = geoProvinceSelected!.geoId
        } else {
            address.province = ""
            address.geoProvinceId = 0
        }
        
        if geoCitySelected != nil {
            address.city = geoCitySelected!.geoName
            address.geoCityId = geoCitySelected!.geoId
        } else {
            address.city = ""
            address.geoCityId = 0
        }
        
        var recordFound = false
        
        for i in 0..<geoRecords.count {
            if geoRecords[i].geoCountryId == address.geoCountryId {
                geoRecords[i].geoProvinceId = address.geoProvinceId
                geoRecords[i].geoCityId = address.geoCityId
                
                recordFound = true
                break
            }
        }
        
        if !recordFound {
            var geoRecord = GeoRecord()
            geoRecord.geoCountryId = address.geoCountryId
            geoRecord.geoProvinceId = address.geoProvinceId
            geoRecord.geoCityId = address.geoCityId
            
            geoRecords.append(geoRecord)
        }
        
        if address.province.length > 0 && address.city.length > 0 {
            provinceAndCityTextField?.text = "\(address.province), \(address.city)"
        } else if address.city.length > 0 {
            provinceAndCityTextField?.text = address.city
        } else {
            provinceAndCityTextField?.text = ""
        }
    }
    
    private func isValidPhone(_ phone: String, countryCode: String) -> Bool {
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
    
    private func isValidPostalCode(_ postalCode: String, countryCode: String, isTyping: Bool = false) -> Bool {
        if countryCode == Constants.CountryMobileCode.HK {
            let validCharacters = RegexManager.matchesForRegexInText("\\d+", text: postalCode)
            
            // Limit on typing only
            if isTyping {
                return postalCode.length == 0 || (!validCharacters.isEmpty && validCharacters.first?.length == postalCode.length && postalCode.length <= 6)
            }
        } else if countryCode == Constants.CountryMobileCode.DEFAULT {
            let validCharacters = RegexManager.matchesForRegexInText("\\d+", text: postalCode)
            
            if isTyping {
                return postalCode.length == 0 || (!validCharacters.isEmpty && validCharacters.first?.length == postalCode.length && postalCode.length <= 6)
            } else {
                return (!validCharacters.isEmpty && validCharacters.first?.length == postalCode.length && postalCode.length == 6)
            }
        }
        
        return true
    }
    
    //MARK: CollectionView Data Source, Delegate Method
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddressAdditionCellID, for: indexPath) as! AddressAdditionCell

        cell.placeholder = placeholders[indexPath.row]
        cell.textField.inputView = nil
        cell.textField.inputAccessoryView = nil
        cell.textField.delegate = self
        cell.textField.isEnabled = true
        cell.textField.keyboardType = .default
        cell.textField.returnKeyType = .done
        cell.textField.addTarget(self, action: #selector(self.textFieldDidChanged), for: UIControlEvents.editingChanged)
        cell.textView.returnKeyType = .done
        cell.textView.delegate = self
        cell.hiddenTextField(false)
        cell.hiddenArrowView(true)
        cell.textField.tag = indexPath.row
        cell.removeMarginLeft = false
        cell.removeMarginRight = false
        if let indexPathRow = IndexPathRow(rawValue: indexPath.row) {
            switch indexPathRow {
            case .receiverName:
                
                cell.textField.text = address.recipientName
                self.receiverNameTextField = cell.textField
                
            case .country:
                cell.textField.text = address.country
                cell.textField.inputView = countryInputView
                cell.hiddenArrowView(false)
                
                countryTextField = cell.textField
            case .phoneCode:
                cell.textField.text = address.phoneCode
                cell.textField.keyboardType = .phonePad
                cell.textField.isEnabled = false
                cell.removeMarginRight = true
                
                phoneCodeTextField = cell.textField
            case .phoneNumber:
                
                let keyboardDoneButtonView = UIToolbar()
                keyboardDoneButtonView.sizeToFit()
//                let doneButton = UIBarButtonItem(title: String.localize("LB_DONE"), style: .Done, target: self, action: #selector(AddressAdditionViewController.doneAction(_:)))
//                doneButton.tintColor = UIColor.black
                
                
                
                let doneButton = createDoneButton()
                
                let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
                keyboardDoneButtonView.items = [flexibleSpaceBarButton, doneButton]
                cell.textField.inputAccessoryView = keyboardDoneButtonView
                
                cell.textField.text = address.phoneNumber
                cell.textField.keyboardType = .numberPad
                cell.removeMarginLeft = true
                
                self.phoneNumberTextField = cell.textField
                
            case .address:
                if address.province.length > 0 && address.city.length > 0 {
                    cell.textField.text = "\(address.province), \(address.city)"
                } else if address.city.length > 0 {
                    cell.textField.text = address.city
                } else {
                    cell.textField.text = ""
                }
                
                cell.textField.inputView = provinceAndCityInputView
                cell.hiddenArrowView(false)
                
                provinceAndCityTextField = cell.textField

               
                arrowCountryAndProvice = cell.arrowView
                
                
            case .streetAddress:
                cell.textField.delegate = self
                cell.hiddenTextField(true)
                
                cell.textViewBeginEditing = {
                    self.activeTextView = cell.textView
                    self.activeTextField = nil
                }
                
                cell.textViewEndEditing = {
                    self.activeTextView = nil
                }
                
                cell.textViewTextChanged = { (text: String) -> Void in
                    self.address.address = text
                }
                
                self.addressCell = cell
                
                if address.address.length > 0 {
                    cell.textView.text = address.address
                }
                
                self.streetAddressTextView = cell.textView
                
                
            case .postalZip:
                cell.textField.keyboardType = .numberPad    // Use NumberPad until we support the country with postal code in text
                
                let keyboardDoneButtonView = UIToolbar()
                keyboardDoneButtonView.sizeToFit()
                
                let doneBtn = createDoneButton()
                
                let flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
                keyboardDoneButtonView.items = [flexibleSpaceBarButton, doneBtn]
                cell.textField.inputAccessoryView = keyboardDoneButtonView
                
                cell.textField.text = address.postalCode
                
                self.postalCodeTextField = cell.textField
            }
            
            if arrayTextFieldValids.contains(cell.textField.tag) {
                
                cell.textField.shouldHighlight(false)
                
            } else {
                
                cell.textField.setStyleDefault()
                
            }
        }
        
        return cell
    }
    
    func createDoneButton() -> UIBarButtonItem {
        
        let doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: self.view.frame.size.width - 30, y: 10, width: 50, height: 30)
        doneButton.setTitle(String.localize("LB_DONE"), for: UIControlState())
        doneButton.setTitleColor(UIColor.redDoneButton(), for: UIControlState())
        doneButton.addTarget(self, action: #selector(AddressAdditionViewController.doneAction), for: .touchUpInside)
        return UIBarButtonItem(customView: doneButton)
    }
    
    @objc func doneAction(_ sender: Any?) {
       self.view.endEditing(true)
    }
    
    func getDefaultCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DefaultCellID, for: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 27, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let indexPathRow = IndexPathRow(rawValue: indexPath.row) {
            switch indexPathRow {
            case .phoneCode:
                return CGSize(width: PhoneCodeCellWidth, height: DefaultCellHeight)
            case .phoneNumber:
                return CGSize(width: self.view.frame.width - PhoneCodeCellWidth, height: DefaultCellHeight)
            case .streetAddress:
                return CGSize(width: self.view.frame.width, height: AddressCellHeight)
            default:
                break
            }
        }
        
        return CGSize(width: self.view.frame.width, height: DefaultCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

    }
    
    // MARK: Picker Data Source, Delegate method
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == provinceAndCityPicker {
            return 2
        } else if pickerView == countryPicker {
            return 1
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == provinceAndCityPicker {
            switch component {
            case 0:
                return geoProvinces.count
            case 1:
                return geoCities.count
            default:
                break
            }
        } else if pickerView == countryPicker {
            return countryPickerDataSource.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == provinceAndCityPicker {
            switch component {
            case 0:
                if row < geoProvinces.count {
                    return geoProvinces[row].geoName
                }
            case 1:
                if row < geoCities.count {
                    return geoCities[row].geoName
                }
            default:
                break
            }
        } else if pickerView == countryPicker {
            return countryPickerDataSource[row].geoCountryName + " (\(countryPickerDataSource[row].mobileCode))"
        }
        
        return ""
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        if let provinceTextField = self.provinceAndCityTextField {
            
            provinceTextField.setStyleDefault()
            arrowCountryAndProvice.isHidden = false
        }

        if pickerView == countryPicker {
            if countryPickerDataSource.count > 0 && row < countryPickerDataSource.count {
                selectCountryInPicker(withPhoneCode: countryPickerDataSource[row].mobileCode, selectRow: false)
            }
        } else if pickerView == provinceAndCityPicker {
            switch component {
            case 0:
                if row < geoProvinces.count {
                    geoProvinceSelected = geoProvinces[row]
                    firstly {
                        return self.listGeoCity(geoProvinces[row].geoId)
                        }.then { _ -> Void in
                            self.updateGeoContent()
                        }.catch { _ -> Void in
                            Log.error("error")
                    }
                }
                
            case 1:
                if row < geoCities.count {
                    geoCitySelected = geoCities[row]
                    updateGeoContent()
                }
            default:
                break
            }
        }
    }
    
    // MARK: KeyboardWillShow/Hide callback
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue) {
            let keyboardSize = keyboardFrame.cgRectValue.size
            let offset = (self.collectionView.frame.maxY + keyboardSize.height + Constants.BottomButtonContainer.Height ) - self.view.frame.height
            if offset > 0{
                let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: offset, right: 0.0)
                 collectionView.contentInset =  contentInsets
                 collectionView.scrollIndicatorInsets = contentInsets
            }
            if let activeTextField = self.activeTextField {
                let rect = collectionView.convert(activeTextField.bounds, from: activeTextField)
                collectionView.scrollRectToVisible(rect, animated: false)
            } else if let activeTextView = self.activeTextView {
                let rect = collectionView.convert(activeTextView.bounds, from: activeTextView)
                collectionView.scrollRectToVisible(rect, animated: false)
            }
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
    }
    
    // MARK: TextField delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        self.activeTextField = nil
        self.activeTextView = nil
        
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let textFieldText = textField.text {
            let prospectiveText = (textFieldText as NSString).replacingCharacters(in: range, with: string)
            
            if let indexPathRow = IndexPathRow(rawValue: textField.tag) {
                switch indexPathRow {
                case .receiverName:
                    address.recipientName = prospectiveText
                case .phoneNumber:
                    if prospectiveText.isNumberic() {
                        address.phoneNumber = prospectiveText
                    } else {
                        return false
                    }
                case .postalZip:
                    if isValidPostalCode(prospectiveText, countryCode: address.phoneCode, isTyping: true) {
                        address.postalCode = prospectiveText
                    } else {
                        return false
                    }
                default:
                    break
                }
            }
        }
        
        return true
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        
//        if let provinceTextField = self.provinceAndCityTextField, let text = provinceTextField.text, text.isEmpty {
//            
//            provinceTextField.setStyleDefault()
//        }
        
        self.activeTextField = textField
        self.activeTextView = nil
        
        if let indexPathRow = IndexPathRow(rawValue: textField.tag) {
            if indexPathRow == .country {
                selectCountryInPicker(withPhoneCode: address.phoneCode, selectRow: true)
            } else if indexPathRow == .address {
                updateGeoContent()
            }
        }
        
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
        
        if let indexPathRow = IndexPathRow(rawValue: textField.tag) {
            if indexPathRow == .country {
                selectCountryInPicker(withPhoneCode: address.phoneCode, selectRow: true)
            } else if indexPathRow == .phoneCode {
                selectCountryInPicker(withPhoneCode: textField.text!, selectRow: true)
            } else if indexPathRow == .address {
                if let inputView = textField.inputView as? AddressInputView {
                    let provinceIndex = inputView.pickerView.selectedRow(inComponent: 0)
                    
                    if provinceIndex != -1 && provinceIndex < geoProvinces.count {
                        geoProvinceSelected = geoProvinces[provinceIndex]
                        
                        firstly {
                            return self.listGeoCity(geoProvinces[provinceIndex].geoId)
                        }.then { _ -> Void in
                            self.provinceAndCityPicker.reloadAllComponents()
                        }.catch { _ -> Void in
                            Log.error("error")
                        }
                        
                        let cityIndex = inputView.pickerView.selectedRow(inComponent: 1)
                        
                        if cityIndex != -1 && cityIndex < geoCities.count {
                            geoCitySelected = geoCities[cityIndex]
                        }
                        
                        updateGeoContent()
                    }
                }
            }
        }
    }
    
    @objc func textFieldDidChanged(_ textField: UITextField){
        textField.setStyleDefault()
        
        if let indexPathRow = IndexPathRow(rawValue: textField.tag) {
            switch indexPathRow {
            case .receiverName:
                address.recipientName = (textField.text ?? "").trim()
                break
            default:
                break
            }
        }
    }
    
    //MARK: - TextView Delegate
    
    func textViewDidChange(_ textView: UITextView) {
        textView.setStyleDefault()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
