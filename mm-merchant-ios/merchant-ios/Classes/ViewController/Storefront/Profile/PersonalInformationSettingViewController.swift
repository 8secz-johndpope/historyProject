//
//  PersonalInformationSettingViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 19/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import UIKit
import ObjectMapper
import PromiseKit

class PersonalInformationSettingViewController: AccountSettingBaseViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, ImagePickerManagerDelegate, DateOfBirthInputViewProtocol, UITextViewDelegate {
    
    private enum SectionType: Int {
        case accountInformation = 0,
        personalInformation
    }
    
    private enum TextFieldTag: Int {
        case textfieldCountry = 90
    }
    
    private final let ProfileViewCellHeight: CGFloat = 58
    private final let PickerHeight: CGFloat = 206
    
    private var nameSettingsData: SettingsData!
    private var nicknameSettingsData: SettingsData!
    private var locationSettingsData: SettingsData!
    private var genderSettingsData: SettingsData!
    private var dateOfBirthSettingsData: SettingsData!
    private var countryCodeSettingData: SettingsData!
    private var personalInformationCell: PersonalInformationSettingMenuCell!
    private var locationDataCell: PersonalInformationSettingMenuCell!
    
    // Location View
    var locationPicker: UIPickerView!
    
    // Coutry Code View
    var countryCodePicker: UIPickerView!
    var countryPickerDataSource = Array<GeoCountry> ()
    var geoCountrySelected: GeoCountry?
    var rowCountrySelected = 0
    var textfieldActived = false
    
    // Location Data Source
    private var geoProvinces = [GeoProvince]()
    private var geoCities = [GeoCity]()
    
    // Location selected
    var geoProvinceSelected: GeoProvince?
    var geoCitySelected: GeoCity?

    var provinceAndCityValueLabel: UILabel?
    var dateOfBirthValueLabel: UILabel?
    
    private var imagePickerManager: ImagePickerManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_PERSONAL_INFO")
        
        setupDismissKeyboardGesture()
        
        createBackButton()
        prepareDataList()
        setupSubViews()
        
        //Load All User information and Locations
        loadViewData()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateUserView()
    }

    override func backButtonClicked(_ button: UIButton) {
        if locationSettingsData.isEditting == true {
            locationSettingsData.isEditting = false
        }
        super.backButtonClicked(button)
    }
    // MARK: - Setup Views
    
    private func prepareDataList() {
        nameSettingsData = SettingsData(title: String.localize("LB_CA_NAME"), action: { (indexPath) in
            self.navigationController?.push(NameSettingViewController(), animated: true)
        })
        
        nicknameSettingsData = SettingsData(title: String.localize("LB_CA_NICKNAME"), action: { (indexPath) in
            self.navigationController?.push(NicknameSettingViewController(), animated: true)
        })
        
        genderSettingsData = SettingsData(title: String.localize("LB_CA_GENDER"), action: { (indexPath) in
            self.selectGender()
        })
        
        locationSettingsData = SettingsData(title: String.localize("LB_CA_MY_ACCT_LOCATION"), action: { (indexPath) in
            if indexPath != nil {
                let cell = self.collectionView.cellForItem(at: indexPath!) as! PersonalInformationSettingMenuCell
                
                if self.geoProvinceSelected == nil {
                    if self.geoProvinces.count > 0 {
                        self.geoProvinceSelected = self.geoProvinces[0]
                        self.loadCity(geoProvince: self.geoProvinces[0])
                    }
                } else {
                    self.pickerViewScrollToSelectedProvince(animated: false)
                    self.pickerViewScrollToSelectedCity(animated: false)
                }
                
                cell.showPickerView()
                self.locationSettingsData.isEditting = true
            }
        })
        
        dateOfBirthSettingsData = SettingsData(title: String.localize("LB_CA_DOB"), action: { (indexPath) in
            if indexPath != nil {
                
                if let birthDate = self.dateOfBirthSettingsData.value, birthDate.length > 0 {
                    Alert.alertWithSingleButton(self, title: "", message: String.localize("LB_CA_USER_INFORMATION_UNEDITABLE"))
                } else {
                    if let cell = self.collectionView.cellForItem(at: indexPath!) as? PersonalInformationSettingMenuCell {
                        cell.showPickerView()
                    }
                }
                
            }
        })
        
        settingsDataList.append([
            SettingsData(title: String.localize("LB_CA_PROFILE_PIC")),
            nameSettingsData,
            nicknameSettingsData,
            genderSettingsData,
            SettingsData(title: String.localize("LB_CA_MY_QRCODE"), imageName: "icon_qr_code", hasBorder: true, action: { (indexPath) in
                MyQRCodeViewController.presentQRCodeController(self)
            })
        ])
        
        settingsDataList.append([])
        
        countryCodeSettingData = SettingsData(title: String.localize("LB_CA_MY_ACCT_COUNTRY"), action: { (indexPath) in
            if indexPath != nil {
                let cell = self.collectionView.cellForItem(at: indexPath!) as! PersonalInformationSettingMenuCell
                cell.showPickerView()
            }
        })
        
        settingsDataList.append([
            
            countryCodeSettingData,
            locationSettingsData,
            dateOfBirthSettingsData,
            SettingsData(title: String.localize("LB_CA_ID_CARD_VER"), action: { (indexPath) in
                let viewController = IDCardCollectionPageViewController(updateCardAction: .setting)
                self.navigationController?.push(viewController, animated: true)
            })
        ])
    }
    
    private func setupSubViews() {
        collectionView.register(PersonalInformationSettingProfileCell.self, forCellWithReuseIdentifier: PersonalInformationSettingProfileCell.CellIdentifier)
        collectionView.register(PersonalInformationSettingMenuCell.self, forCellWithReuseIdentifier: PersonalInformationSettingMenuCell.CellIdentifier)
        collectionView.backgroundColor = UIColor.primary2()
    }
    
    // MARK: - Location
    
    private func setLocation(reloadCollectionView: Bool = true) {
        if user.geoCountryId > 0 && geoProvinceSelected!.geoId > 0 && geoCitySelected!.geoId > 0 {
            firstly {
                return updateLocation(geoCountryId: user.geoCountryId, geoProvinceId: geoProvinceSelected!.geoId, geoCityId: geoCitySelected!.geoId)
            }.then { _ -> Void in
                self.updateUserView(reloadCollectionView: reloadCollectionView)
            }
        }
    }
    
    // Load the city list base on selected province
    private func loadCity(geoProvince: GeoProvince) {
        firstly {
            return self.listGeoCity(geoProvince.geoId)
        }.then { _ -> Void in
            if self.geoCities.count > 0 {
                self.geoCitySelected = self.geoCities[0]
                self.reloadAllData(reloadCollectionView: false)
            }
            
            if self.geoProvinceSelected != nil {
                self.pickerViewScrollToSelectedProvince(animated: false)
                self.pickerViewScrollToSelectedCity(animated: false)
            }
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    private func listGeoCity(_ geoProvinceId: Int, completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            GeoService.storefrontCities(geoProvinceId, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        if response.response?.statusCode == 200 {
                            if let geoCities = Mapper<GeoCity>().mapArray(JSONObject: response.result.value) {
                                strongSelf.geoCities = geoCities
                                
                                if strongSelf.geoCitySelected == nil && geoCities.count > 0 {
                                    strongSelf.geoCitySelected = geoCities[0]
                                }
                            }
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    private func listGeoProvince(_ geoCountryId: Int, completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            GeoService.storefrontProvinces(geoCountryId, completion: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess{
                        if response.response?.statusCode == 200 {
                            if let geoProvinces = Mapper<GeoProvince>().mapArray(JSONObject: response.result.value) {
                                strongSelf.geoProvinces = geoProvinces
                            }
                            fulfill("OK")
                        } else {
                            strongSelf.handleApiResponseError(response, reject: reject)
                        }
                    } else {
                        reject(response.result.error!)
                    }
                }
            })
        }
    }
    
    // MARK: - Collection View Data Source methods
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let settingsData = settingsDataList[indexPath.section][indexPath.item]
        
        if indexPath.section == SectionType.accountInformation.rawValue && indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalInformationSettingProfileCell.CellIdentifier, for: indexPath) as! PersonalInformationSettingProfileCell
            
            cell.itemLabel.text = settingsData.title
            cell.showBorder(settingsData.hasBorder)
            
            let gesture = UITapGestureRecognizer(target: self, action: #selector(PersonalInformationSettingViewController.changeProfileImage))
            cell.profileImageView.addGestureRecognizer(gesture)
            
            cell.tappedDisclosureIndicator = {
                self.changeProfileImage()
            }
            
            if user.profileImage.length > 0 {
                cell.setProfileImage(user.profileImage)
            } else {
                cell.setProfileImage("")
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PersonalInformationSettingMenuCell.CellIdentifier, for: indexPath) as! PersonalInformationSettingMenuCell
            
            cell.itemLabel.text = settingsData.title
            cell.valueLabel.text = settingsData.value
            
            if settingsData.imageName != nil {
                cell.setValueImage(imageName: settingsData.imageName!)
            } else {
                cell.valueImageView.image = nil
            }
            
            cell.showBorder(settingsData.hasBorder)
            
            if settingsData == countryCodeSettingData {
                
                let contryCodeInputView = ContryCodeInputView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: PickerHeight))
                self.countryCodePicker = contryCodeInputView.pickerView
                countryCodePicker.delegate = self
                countryCodePicker.dataSource = self
                cell.itemTextField.inputView = contryCodeInputView
                cell.itemTextField.delegate = self
                cell.itemTextField.tag = TextFieldTag.textfieldCountry.rawValue
                cell.itemTextField.delegate = self
                provinceAndCityValueLabel = cell.valueLabel
                contryCodeInputView.doneButtonTappedHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.view.endEditing(true)
                    }
                }
                
                personalInformationCell = cell
                
                
            } else if settingsData == locationSettingsData {
                let inputAddressView = AddressInputView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: PickerHeight))
                self.locationPicker = inputAddressView.pickerView
                locationPicker.delegate = self
                locationPicker.dataSource = self
                cell.itemTextField.inputView = inputAddressView
                cell.itemTextField.delegate = self
                locationPicker.reloadAllComponents()
                locationDataCell = cell
                provinceAndCityValueLabel = cell.valueLabel
                inputAddressView.doneButtonTappedHandler = { [weak self] in
                    if let strongSelf = self {
                        strongSelf.view.endEditing(true)
                        strongSelf.setLocation(reloadCollectionView: false)
                    }
                }
            } else if settingsData == dateOfBirthSettingsData {
                let inputDateOfBirthView = DateOfBirthInputView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: PickerHeight + 40))
                if let date = user.dateOfBirth {
                    inputDateOfBirthView.datePicker.setDate(date, animated: true)
                }
                inputDateOfBirthView.delegate = self
                cell.itemTextField.inputView = inputDateOfBirthView
                
                dateOfBirthValueLabel = cell.valueLabel
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if let sectionType = SectionType(rawValue: section) {
            switch sectionType {
            case .accountInformation:
                return UIEdgeInsets(top: 10.0, left: 0.0, bottom: 5.0, right: 0.0)
            case .personalInformation:
                return UIEdgeInsets(top: 5.0, left: 0.0, bottom: 5.0, right: 0.0)
            }
        } else {
            return UIEdgeInsets.zero
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 && indexPath.item == 0 {
            return CGSize(width: view.width, height: ProfileViewCellHeight)
        } else {
            return CGSize(width: view.width, height: PersonalInformationSettingMenuCell.DefaultHeight)
        }
    }
    
    // MARK: - View Data
    
    // Load all user information, province and city
    private func loadViewData() {
        firstly {
            return fetchUser()
        }.then { _ -> Promise<Any> in
            self.reloadAllData()
            return self.listGeoProvince(self.user.geoCountryId)
        }.then { _ -> Void in
            self.loadSelectedUserLocation(false)
        }.then { _ -> Void in
            self.listGeoCountry()
        }.catch { _ -> Void in
            Log.error("error")
        }
    }
    
    // To find geo objects of user
    private func loadSelectedUserLocation(_ isShowLocationPicker: Bool) {
        if geoProvinces.count > 0 {
            //Get selected Geo Province
            var provinceValue = geoProvinces.filter({ $0.geoId == self.user.geoProvinceId })
            
            if provinceValue.count > 0 {
                self.geoProvinceSelected = provinceValue[0]
                
                firstly {
                    // Get cities
                    self.listGeoCity(self.geoProvinceSelected!.geoId)
                }.then { _ -> Void in
                    // Get Selected Geo City
                    if self.geoCities.count > 0 {
                        var cityValue = self.geoCities.filter({ $0.geoId == self.user.geoCityId })
                        
                        if cityValue.count > 0 {
                            self.geoCitySelected = cityValue[0]
                        }
                        
                        if isShowLocationPicker && self.locationDataCell != nil {
                            self.locationDataCell.showPickerView()
                            self.locationPicker.reloadAllComponents()
                            self.pickerView(self.locationPicker, didSelectRow: 0, inComponent: 0)
                            self.pickerView(self.locationPicker, didSelectRow: 0, inComponent: 1)
                            self.locationSettingsData.isEditting = true
                        }
                    }
                    self.stopLoading()
                }.catch { _ -> Void in
                    self.stopLoading()
                }
            } else {
                // If user didn't select any province before we would load city base on the first province
                if geoProvinces.count > 0 {
                    let firstProvince = geoProvinces[0]
                    
                    if self.geoProvinceSelected == nil {
                        self.geoProvinceSelected = firstProvince
                    }
                    firstly {
                        // get cities
                        self.listGeoCity(firstProvince.geoId)
                    }.then { _ -> Void in
                        self.stopLoading()
                        if isShowLocationPicker && self.locationDataCell != nil {
                            self.locationDataCell.showPickerView()
                            self.locationPicker.reloadAllComponents()
                            self.pickerView(self.locationPicker, didSelectRow: 0, inComponent: 0)
                            self.pickerView(self.locationPicker, didSelectRow: 0, inComponent: 1)
                            self.locationSettingsData.isEditting = true
                        }
                    }.catch { _ -> Void in
                        self.stopLoading()
                    }
                }
            }
        } else {
            self.stopLoading()
        }
    }
    
    private func reloadAllData(reloadCollectionView: Bool = true) {
        nameSettingsData.value = "\(user.lastName) \(user.firstName)"
        nicknameSettingsData.value = "\(user.displayName)"
        
        if let birth = user.dateOfBirth  {
            dateOfBirthSettingsData.value = Constants.DateFormatter.getFormatter(DateTransformExtension.DateFormatStyle.dateOnly).string(from: birth)
        }else {
            dateOfBirthSettingsData.value = ""
        }
        
        
        // Location
        var locationValue = ""
        
        if geoProvinceSelected != nil {
            locationValue = geoProvinceSelected!.geoName
        }
        
        if geoCitySelected != nil {
            locationValue = locationValue + ", " + geoCitySelected!.geoName
        }
        
        locationSettingsData.value = locationValue
        
        // Gender
        if user.gender == Constants.Gender.Male {
            genderSettingsData.value = String.localize("LB_CA_GENDER_M")
        } else if user.gender == Constants.Gender.Female {
            genderSettingsData.value = String.localize("LB_CA_GENDER_F")
        }
        
        
        //contry code 
        
        var cc = ""
        
        if let countryCode = geoCountrySelected {
            cc = countryCode.geoCountryName
        }
        
        countryCodeSettingData.value = cc
        
        if reloadCollectionView {
            collectionView.reloadData()
        } else {
            provinceAndCityValueLabel?.text = locationSettingsData.value
            dateOfBirthValueLabel?.text = dateOfBirthSettingsData.value
        }
    }
    
    private func updateUserView(reloadCollectionView: Bool = true) {
        firstly {
            return fetchUser()
        }.then { _ -> Void in
            self.reloadAllData(reloadCollectionView: reloadCollectionView)
        }
    }
    
    private func updateGender(_ gender: String) -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.updateGender(gender: gender) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            fulfill("OK")
                        } else {
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
    
    private func updateLocation(geoCountryId: Int, geoProvinceId: Int, geoCityId: Int) -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.updateLocation(geoCountryId: geoCountryId, geoProvinceId: geoProvinceId, geoCityId: geoCityId) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
							strongSelf.showSuccessPopupWithText(String.localize("MSG_CA_MY_ACCT_CHANGE_GEO_INFO_SUC"))
                            fulfill("OK")
                        } else {
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
    @discardableResult
    private func updateDateOfBirth(_ dateOfBirth: Date, reloadCollectionView: Bool) -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.updateDateOfBirth(dateOfBirth: dateOfBirth) { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
							
							strongSelf.showSuccessPopupWithText(String.localize("MSG_CA_MY_ACCT_CHANGE_PERSONAL_INFO_SUC"), isAddWindow: true)
                            
                            strongSelf.updateUserView(reloadCollectionView: reloadCollectionView)
                            fulfill("OK")
                        } else {
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
    
    
    // get country code
    @discardableResult
    func listGeoCountry(completion complete:(() -> Void)? = nil) -> Promise<Any> {
        return Promise{ fulfill, reject in
            GeoService.storefrontCountries({ [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            let countries: Array<GeoCountry> = Mapper<GeoCountry>().mapArray(JSONObject: response.result.value)!
                            strongSelf.countryPickerDataSource = countries
                            
                            if let index = countries.index(where: {$0.geoCountryId == strongSelf.user.geoCountryId}){
                                strongSelf.geoCountrySelected = countries[index]
                                strongSelf.rowCountrySelected = index
                            }
                            strongSelf.reloadAllData()
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
    
    @objc func changeProfileImage() {
        if imagePickerManager == nil {
            imagePickerManager = ImagePickerManager(viewController: self, withDelegate: self)
        }
        
        imagePickerManager!.presentDefaultActionSheet(preferredCameraDevice: .front)
    }
    
    // MARK: - Picker View Data Source, Delegate methods
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if pickerView == locationPicker {
            return 2
        } else if pickerView == countryCodePicker {
            return 1
        }
        
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == locationPicker {
            switch component {
            case 0:
                return geoProvinces.count
            case 1:
                return geoCities.count
            default:
                break
            }
        } else if pickerView == countryCodePicker {
            return countryPickerDataSource.count
        }
        
        return 0
    }
	
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        switch pickerView {
        case locationPicker:
            var titleViewRow = ""
            
            switch component {
            case 0:
                if row < geoProvinces.count {
                    titleViewRow = geoProvinces[row].geoName
                }
            case 1:
                if row < geoCities.count {
                    titleViewRow = geoCities[row].geoName
                }
            default:
                break
            }
            
            return viewPicker(titleViewRow)
        case countryCodePicker:
            let countryCode = countryPickerDataSource[row]
            let titleViewRow = countryCode.geoCountryName + "(\(countryCode.mobileCode))"
            
            return viewCCPicker(titleViewRow)
        default:
            return UILabel()
        }
    }
    
    func viewPicker(_ titleRow: String) -> UILabel {
        let pickerLabel = UILabel()
        pickerLabel.textAlignment = .center
        pickerLabel.text = titleRow
        pickerLabel.formatSize(14)
        pickerLabel.font = UIFont.systemFont(ofSize: 22)
        return pickerLabel
    }
    
    func viewCCPicker(_ titleRow: String) -> UILabel {
        let pickerLabel = UILabel()
        pickerLabel.textAlignment = .center
        pickerLabel.text = titleRow
        pickerLabel.formatSize(22)
        pickerLabel.textColor = UIColor.black
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == locationPicker {
            switch component {
            case 0:
                if self.geoProvinces.count > row {
                    geoProvinceSelected = geoProvinces[row]
                    loadCity(geoProvince: geoProvinces[row])
                }
            case 1:
                if self.geoCities.count > row {
                    geoCitySelected = geoCities[row]
                }
            default:
                break
            }
            
            self.reloadAllData(reloadCollectionView: false)
        } else if pickerView == countryCodePicker {
            if countryPickerDataSource.count > row {
                geoCountrySelected = countryPickerDataSource[row]
                
                if let geo = geoCountrySelected {
                    self.user.geoCountryId = geo.geoCountryId
                    self.user.mobileCode = geo.mobileCode
                    rowCountrySelected = row
                    self.personalInformationCell.valueLabel.text = geo.geoCountryName
                    
                    firstly {
                        return listGeoProvince(self.user.geoCountryId)
                        }.then { _ -> Void in
                            self.view.endEditing(true)
                            self.loadSelectedUserLocation(true)
                        }.then { _ -> Void in
                            if self.locationDataCell != nil {
                                self.locationDataCell.valueLabel.text = ""
                            }
                    }
                }
            }
        }
    }
    
    func pickerViewScrollToSelectedCity (animated:Bool) {
        // Reload city rows
        self.locationPicker.reloadComponent(1)
        
        //Find index city
        if self.geoCitySelected != nil {
            if geoCities.count > 0 {
                if let indexGeoCity: Int = geoCities.index(where: { $0 === self.geoCitySelected! }) {
                    self.locationPicker.selectRow(indexGeoCity, inComponent: 1, animated: animated)
                }
            }
        }
    }
    
    func pickerViewScrollToSelectedProvince(animated:Bool) {
        // Reload province rows
        self.locationPicker.reloadComponent(0)
        
        //Find index province
        if geoProvinces.count > 0 {
            if let indexGeoProvince: Int = geoProvinces.index(where: { $0 === self.geoProvinceSelected! }) {
                self.locationPicker.selectRow(indexGeoProvince, inComponent: 0, animated: animated)
            }
        }
    }
    
    // MARK: - Gender
    
    private func selectGender() {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let maleAction = UIAlertAction(title: String.localize("LB_CA_GENDER_M"), style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.setGender(Constants.Gender.Male)
        })
        
        let femaleAction = UIAlertAction(title: String.localize("LB_CA_GENDER_F"), style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.setGender(Constants.Gender.Female)
        })
        
        let cancelAction = UIAlertAction(title: String.localize("LB_CANCEL"), style: .cancel, handler: nil)
        
        optionMenu.addAction(maleAction)
        optionMenu.addAction(femaleAction)
        optionMenu.addAction(cancelAction)
		
		optionMenu.view.tintColor = UIColor.secondary2()
		
        self.present(optionMenu, animated: true, completion: nil)
        optionMenu.view.tintColor = UIColor.alertTintColor()
    }
    
    private func setGender(_ gender: String) {
        firstly {
            return updateGender(gender)
        }.then { _ -> Void in
            self.updateUserView()
        }
    }
    
    // MARK: - KeyboardWilShow/Hide callback
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        let keyboardInfoKey = notification.userInfo![UIKeyboardFrameEndUserInfoKey]
        
        if keyboardInfoKey != nil {
            let keyboardHeight = (keyboardInfoKey as! NSValue).cgRectValue.size.height
            
            collectionView.frame.sizeHeight = view.frame.sizeHeight - collectionView.frame.originY - tabBarHeight - keyboardHeight
            
            // Scroll to bottom
            if (collectionView.frame.sizeHeight - keyboardHeight) > collectionView.contentSize.height {
                collectionView.setContentOffset(CGPoint(x: 0, y: collectionView.contentSize.height - collectionView.frame.sizeHeight), animated: true)
            }
        }
        
        if textfieldActived {
            countryCodePicker.selectRow(rowCountrySelected, inComponent: 0, animated: false)
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.frame.sizeHeight = view.frame.sizeHeight - collectionView.frame.originY - tabBarHeight
        textfieldActived = false
        if self.locationSettingsData.isEditting == true {
            self.locationSettingsData.isEditting = false
            self.setLocation(reloadCollectionView: true)
        }
    }
    
    // MARK: - ImagePickerManagerDelegate
    
    func didPickImage(_ image: UIImage!) {
        if image.size.width > 0 {
            showLoading()
            
            UserService.uploadImage(image, imageType: .profile, success: { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            if let imageUploadResponse = Mapper<ImageUploadResponse>().map(JSONObject: response.result.value) {
                                strongSelf.user.profileImage = imageUploadResponse.profileImage
								strongSelf.showSuccessPopupWithText(String.localize("MSG_CA_MY_ACCT_CHANGE_PERSONAL_INFO_SUC"))
                                strongSelf.reloadAllData()
                                
                                Context.saveUserProfile(strongSelf.user)
                            }
                        }
                    }
                    
                    strongSelf.stopLoading()
                }
            }, fail: { [weak self] encodingError in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                }
            })
        }
    }
    
    // MARK: - DateOfBirthInputViewDelegate
    
    func didUpdateDateOfBirth(_ date: Date?, closePickerView: Bool) {
        if closePickerView {
            Alert.alert(self, title: "", message: String.localize("LB_CA_BIRTHDAY_CONFIRMATION"), okTitle: String.localize("LB_OK"), okActionComplete: {
                self.view.endEditing(true)
                self.updateDateOfBirth(date!, reloadCollectionView: closePickerView)
            })
        }
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.tag == TextFieldTag.textfieldCountry.rawValue {
            textfieldActived = true
        }
    }
}
