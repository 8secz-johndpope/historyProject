//
//  NameSettingViewController.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 21/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit
import ObjectMapper
import PromiseKit

class NameSettingViewController: AccountSettingBaseViewController, UITextFieldDelegate {
	
	enum IndexPathRow: Int {
		case lastname = 0
		case firstname
		case count
	}

    private final let SectionEdgeInset = UIEdgeInsets(top: 10.0, left: 0.0, bottom: 5.0, right: 0.0)
    private final let FirstNameValueKey = "FirstName"
    private final let LastNameValueKey = "LastName"
    
    private var values = [String : String]()
    private var confirmButtonOriginalY: CGFloat = 0

	private final let NameSettingViewCellID = "NameSettingViewCellID"
	
    private var firstNameTextField: UITextField!
    private var lastNameTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_NAME")
		
        setupDismissKeyboardGesture()
        
		createBackButton()
        createBottomButton(String.localize("LB_CA_CONFIRM"), customAction: #selector(NameSettingViewController.confirm))
        prepareDataList()
		setupSubViews()
        retrieveUser()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Setup Views
    
    private func prepareDataList() {
        values[FirstNameValueKey] = "-"
        values[LastNameValueKey] = "-"
        
        let lastNameSettingsData = SettingsData(title: String.localize("LB_CA_LASTNAME"), valueKey: LastNameValueKey)
        let firstNameSettingsData = SettingsData(title: String.localize("LB_CA_FIRSTNAME"), valueKey: FirstNameValueKey)
        
        settingsDataList.append([lastNameSettingsData, firstNameSettingsData])
    }
    
    private func setupSubViews() {
		collectionView.register(NameSettingViewCell.self, forCellWithReuseIdentifier: NameSettingViewCellID)
		
		let padding: CGFloat = 45 // (extra space for error message pop up)
		
		var rect = collectionView.frame
		rect.origin.y = rect.origin.y + padding
		rect.size.height = rect.size.height - padding
		collectionView.frame = rect
		
		if bottomButtonContainer != nil {
			confirmButtonOriginalY = bottomButtonContainer!.frame.origin.y
		}
    }
	
    // MARK: - Action
    
    @objc func editingDidEndOnExit(_ textField: UITextField) {

        
        if textField.tag == settingsDataList[0].count - 1 {
            // Last item
            dismissKeyboardFromView()
        } else {
            let cell = collectionView.cellForItem(at: IndexPath(item: textField.tag + 1, section: 0)) as! NameSettingViewCell
            cell.textField.becomeFirstResponder()
        }
    }
    
    @objc func confirm(_ button: UIButton) {
        if let sectionSettingsDataList = settingsDataList.first {
            for i in 0..<sectionSettingsDataList.count {
                if let cell = collectionView.cellForItem(at:  IndexPath(item: i, section: 0)) as? NameSettingViewCell {
                    if let valueKey = sectionSettingsDataList[i].valueKey {
                        values[valueKey] = cell.textField.text
                    }
                }
            }
        }
        
        var strongLastName = ""
        var strongFirstName = ""
        
        if let lastName = values[LastNameValueKey] {
            
            strongLastName = lastName
            
        }
        
        if let firstName = values[FirstNameValueKey]{
            
            strongFirstName = firstName
            
        }
        
        guard !(strongLastName.isEmptyOrNil()) else  {
        
            showError(String.localize("MSG_ERR_LASTNAME_NIL"), animated: true)
            lastNameTextField.shouldHighlight(true)
            lastNameTextField.becomeFirstResponder()
            return
        }
        
        guard !(strongLastName.containsEmoji()) else {
            
            showError(String.localize("MSG_ERR_USER_FULLNAME"), animated: true)
            lastNameTextField.shouldHighlight(true)
            lastNameTextField.becomeFirstResponder()
            
            return
            
        }
        
        lastNameTextField.shouldHighlight(false)

        
        guard !(strongFirstName.isEmptyOrNil()) else {
            
            showError(String.localize("MSG_ERR_MERCHANT_FIRSTNAME_NIL"), animated: true)
            firstNameTextField.shouldHighlight(true)
            firstNameTextField.becomeFirstResponder()
            return
        }
        
        
        
        guard !(strongFirstName.containsEmoji()) else {
            showError(String.localize("MSG_ERR_USER_FULLNAME"), animated: true)
            firstNameTextField.shouldHighlight(true)
            firstNameTextField.becomeFirstResponder()
            return
        }
        firstNameTextField.shouldHighlight(false)
        
        
        
            firstly {
                return updateName()
                }.then { _ -> Void in
                    self.showSuccessPopupWithText(String.localize("MSG_CA_MY_ACCT_CHANGE_PERSONAL_INFO_SUC"))
                    self.navigationController?.popViewController(animated:true)
            
        }

    }
    
    // MARK: Observer
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        if let keyboardInfoKey = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect {
            let keyboardHeight = keyboardInfoKey.size.height
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardHeight, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
            if bottomButtonContainer != nil {
                bottomButtonContainer!.frame.originY = confirmButtonOriginalY - keyboardHeight + tabBarHeight
            }
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        if bottomButtonContainer != nil {
            bottomButtonContainer!.frame.originY = confirmButtonOriginalY
        }
    }
    
    // MARK: - Data handling
    
    func retrieveUser() {
        firstly {
            return fetchUser()
        }.then { _ -> Void in
            self.reloadAllData()
        }
    }
    
    func updateName() -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.updateName(firstName: values[FirstNameValueKey]!, lastName: values[LastNameValueKey]!) { [weak self] (response) in
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
    
    func reloadAllData() {
        values[FirstNameValueKey] = user.firstName
        values[LastNameValueKey] = user.lastName
        
        collectionView.reloadData()
    }

    // MARK: - Collection View Data Source methods
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let settingsData = settingsDataList[indexPath.section][indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NameSettingViewCellID, for: indexPath) as! NameSettingViewCell
        
        // Reset content
        cell.textField.text = ""
		
		if let indexPathRow = IndexPathRow(rawValue: indexPath.row) {
			switch indexPathRow {
				case .lastname:
					cell.textField.placeholder = String.localize("LB_CA_LASTNAME")
					cell.textField.returnKeyType = .next
                    self.lastNameTextField = cell.textField
                    
					break
				case .firstname:
					cell.textField.placeholder = String.localize("LB_CA_FIRSTNAME")
					cell.textField.returnKeyType = .done
                    self.firstNameTextField = cell.textField
					break
				default:
				break
			}
			
			cell.textField.delegate = self
            cell.textField.format()
			cell.textField.tag = indexPath.row
			cell.textField.addTarget(self, action: #selector(NameSettingViewController.editingDidEndOnExit), for: .editingDidEndOnExit)
			cell.textField.addTarget(self, action: #selector(NameSettingViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
            
			if let valueKey = settingsData.valueKey {
				if let value = values[valueKey] {
					cell.textField.text = value
				}
			}

		}
		
        return cell
    }
	
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return SectionEdgeInset
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.width, height: NameSettingViewCell.DefaultHeight)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        
        textField.setStyleDefault()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let maxLength = Constants.Value.FistNameLastNameMaxLength
        let currentString: NSString = textField.text as NSString? ?? ""
        let newString: NSString = currentString.replacingCharacters(in: range, with: string) as NSString
        return  newString.length <= maxLength
    }
}
