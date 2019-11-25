//
//  PasswordSettingViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/23/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
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


protocol PasswordSettingDelegate: NSObjectProtocol {
    func didUpdatePassword(isSuccess: Bool)
}

class PasswordSettingViewController: MmViewController, UITextFieldDelegate {
    
    private var oldPasswordTextField: UITextField!
    private var newPasswordTextField: UITextField!
    private var confirmNewPasswordTextField: UITextField!
    private var validationView : UIView!
    let marginVertical: CGFloat = 9
    
    weak var delegate: PasswordSettingDelegate?
    private var confirmButtonOriginalY: CGFloat = 0
    var isDisappear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = String.localize("LB_CA_MY_ACCT_MODIFY_PW")
		
        setupDismissKeyboardGesture()
		
		createBackButton()
		createBottomButton(String.localize("LB_CA_CONFIRM"), customAction: #selector(PasswordSettingViewController.confirm))
        
        if let view = bottomButtonContainer {
            confirmButtonOriginalY = view.frame.origin.y
        }
        
		setupSubViews()
        updateBottomButtonStyle(true, updateState: true)
    }

    // MARK: - Setup Views
    
    private func setupSubViews() {
        let cellHeight: CGFloat = 64
        let marginHorizontal: CGFloat = 11
        let navBarHeightWithPadding: CGFloat = 109 // 64 + 10 + 35 (extra space for error message pop up)
        let textFieldHeight = cellHeight - (marginVertical * 2)
        
        
        oldPasswordTextField = UITextField(frame: CGRect(x: marginHorizontal, y: navBarHeightWithPadding + marginHorizontal, width: view.width - 2 * marginVertical, height: textFieldHeight))
        oldPasswordTextField.format()
        oldPasswordTextField.placeholder = String.localize("LB_CA_OLD_PW")
        oldPasswordTextField.isSecureTextEntry = true
        oldPasswordTextField.delegate = self
        oldPasswordTextField.returnKeyType = .next
        
        oldPasswordTextField.addTarget(self, action: #selector(PasswordSettingViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
        
        view.addSubview(oldPasswordTextField)
        
        newPasswordTextField = UITextField(frame: CGRect(x: marginHorizontal, y: navBarHeightWithPadding + (marginHorizontal * 2) + textFieldHeight, width: view.width - 2 * marginVertical, height: textFieldHeight))
        newPasswordTextField.format()
        newPasswordTextField.placeholder = String.localize("LB_CA_NEW_PW")
        newPasswordTextField.isSecureTextEntry = true
        newPasswordTextField.delegate = self
        newPasswordTextField.returnKeyType = .next
        
        view.addSubview(newPasswordTextField)
        newPasswordTextField.addTarget(self, action: #selector(PasswordSettingViewController.textFieldDidChange), for: UIControlEvents.editingChanged)

        
        validationView = UIView(frame: CGRect(x: marginHorizontal, y: newPasswordTextField.frame.maxY + (marginVertical / 2), width: view.width - 2 * marginVertical, height: 0))
        view.addSubview(validationView)
        
        let padding = CGFloat(13)
        let validationLengthView = ValidationView(frame: CGRect(x: 0, y: 0, width: ValidationView.getWidth(.length), height: ValidationView.ValidationViewHeight), type: ValidationType.length)
        validationView.addSubview(validationLengthView)
        
        let validationLetterView = ValidationView(frame: CGRect(x: validationLengthView.frame.maxX + padding, y: 0, width: ValidationView.getWidth(.letter), height: ValidationView.ValidationViewHeight), type: ValidationType.letter)
        validationView.addSubview(validationLetterView)
        

        confirmNewPasswordTextField = UITextField(frame: CGRect(x: marginHorizontal, y: validationView.frame.maxY + (marginVertical / 2) , width: view.width - 2 * marginVertical, height: textFieldHeight))
		
        confirmNewPasswordTextField.format()

        let validationNumberView = ValidationView(frame: CGRect(x: validationLetterView.frame.maxX + padding, y: 0, width: ValidationView.getWidth(.number), height: ValidationView.ValidationViewHeight), type: ValidationType.number)
        validationView.addSubview(validationNumberView)
		
        validationView.clipsToBounds = true
        
        confirmNewPasswordTextField.placeholder = String.localize("LB_CA_CONF_NEW_PW")
        confirmNewPasswordTextField.isSecureTextEntry = true
        confirmNewPasswordTextField.delegate = self
        confirmNewPasswordTextField.returnKeyType = .done
        
        confirmNewPasswordTextField.addTarget(self, action: #selector(PasswordSettingViewController.textFieldDidChange), for: UIControlEvents.editingChanged)
        view.addSubview(confirmNewPasswordTextField)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        isDisappear = true
    }
    // MARK: - Action
    
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return true
    }
	
    
    func editingDidEndOnExit(_ textField: UITextField) {
        
        switch textField {
        case oldPasswordTextField:
            newPasswordTextField.becomeFirstResponder()
            break
        case newPasswordTextField:
            confirmNewPasswordTextField.becomeFirstResponder()
            break
        case confirmNewPasswordTextField:
            self.dismissKeyboardFromView()
            break
        default:
            break
        }
    }
    
    func isNewPasswordValid()-> Bool {
        var isValid = true
        for subView in validationView.subviews {
            if let view = subView as? ValidationView {
                isValid = ( view.validate(self.newPasswordTextField.text ?? "")  && isValid)
            }
        }
        
        return isValid
    }
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField == newPasswordTextField {
            let isValid = self.isNewPasswordValid()
            if newPasswordTextField.text?.length > 0 {
                self.updateHintsPanel(isShow: isValid ? false : true)
            }else {
                self.updateHintsPanel(isShow: true)
            }
            
            if isValid && textField.text?.length > 0 {
                textField.shouldHighlight(false)
            } else {
                textField.shouldHighlight(true)
            }
            
        } else {
            textField.setStyleDefault()
        }
    }
    
    func updateHintsPanel(isShow: Bool) {
        var rect = validationView.frame
        rect.sizeHeight = isShow ? ValidationView.ValidationViewHeight : 0
        validationView.frame  = rect
        
        confirmNewPasswordTextField.frame.originY = validationView.frame.maxY + (marginVertical / 2)
    }
    
    @objc func confirm(_ button: UIButton) {
		
		if let text = oldPasswordTextField?.text, text.isEmpty {
			showError(String.localize("MSG_ERR_CA_OLD_PW_NIL"), animated: true)
			oldPasswordTextField.shouldHighlight(true)
			oldPasswordTextField.becomeFirstResponder()
			return
		}
		oldPasswordTextField.shouldHighlight(false)

		//validate newPassword
		if let text = newPasswordTextField?.text, text.isEmpty {
			
			showError(String.localize("MSG_ERR_CA_NEW_PW_NIL"), animated: true)
			newPasswordTextField.shouldHighlight(true)
			newPasswordTextField.becomeFirstResponder()
			return
		} else {
			if !self.isNewPasswordValid() {
				showError(String.localize("MSG_ERR_CA_PW_PATTERN"), animated: true)
				newPasswordTextField.shouldHighlight(true)
				newPasswordTextField.becomeFirstResponder()
				return
			}
		}
		
		newPasswordTextField.shouldHighlight(false)

		if let text = confirmNewPasswordTextField?.text, text.isEmpty {
			
			showError(String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"), animated: true)
			confirmNewPasswordTextField.shouldHighlight(true)
			confirmNewPasswordTextField.becomeFirstResponder()
			return
		} else if let newText = newPasswordTextField?.text, newText.length > 0, let confirmText = confirmNewPasswordTextField?.text, (confirmText.length > 0) {
			
			if  newText != confirmText {
				
				showError(String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"), animated: true)
				confirmNewPasswordTextField.shouldHighlight(true)
				confirmNewPasswordTextField.becomeFirstResponder()
				return
			}
			
		}
		confirmNewPasswordTextField.shouldHighlight(false)

		
        firstly {
            return updatePassword(self.oldPasswordTextField.text!, newPassword: self.newPasswordTextField.text!)
        }.then { _ -> Void in
            self.navigationController?.popViewController(animated:true)
            self.delegate?.didUpdatePassword(isSuccess: true)
        }
    }
    
    func checkValidData() -> Bool {
        var isValid = true
        
        if let text = oldPasswordTextField?.text, text.isEmpty {
            
            styleErrorTextField(oldPasswordTextField, message: String.localize("MSG_ERR_CA_OLD_PW_NIL"))
   
        } else if let text = newPasswordTextField?.text, text.isEmpty {
			
            
            styleErrorTextField(newPasswordTextField, message: String.localize("MSG_ERR_CA_NEW_PW_NIL"))
            

            isValid = false
        } else if let text = confirmNewPasswordTextField?.text, text.isEmpty {
			
            styleErrorTextField(confirmNewPasswordTextField, message: String.localize("MSG_ERR_CA_CFM_PW_NIL"))
            
            isValid = false
        } else if newPasswordTextField.text?.length > 0 && RegexManager.matchesForRegexInText(RegexManager.ValidPattern.Password, text: newPasswordTextField.text).isEmpty {
            
            styleErrorTextField(confirmNewPasswordTextField, message: String.localize("MSG_ERR_CA_PW_PATTERN"))
			
            isValid = false
        } else if newPasswordTextField.text != confirmNewPasswordTextField.text {
            
            styleErrorTextField(newPasswordTextField, message: String.localize("MSG_ERR_CA_CFM_PW_NOT_MATCH"))

            isValid = false
        }

		return isValid
		
    }
    
    func styleErrorTextField(_ textField: UITextField?, message: String){
        
        showError(message, animated: true)
        textField?.shouldHighlight(true)
        textField?.becomeFirstResponder()
        
    }
    
    // MARK: - Data
    
    func updatePassword(_ currentPassword: String, newPassword: String) -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.updatePassword(currentPassword: currentPassword, newPassword: newPassword, completion: { [weak self] (response) -> Void in
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
            })
        }
    }

	// MARK: - UITextField Delegate

	func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == newPasswordTextField {
            if textField.text?.length > 0 {
                self.textFieldDidChange(textField)
            }else {
                self.updateHintsPanel(isShow: true)
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {

        if textField == newPasswordTextField {
            if textField.text?.length > 0 {
                self.textFieldDidChange(textField)
            }else {
                self.updateHintsPanel(isShow: true)
            }
        }
        //Fix MM-6759 The password should not show as big dot
        if textField.isSecureTextEntry {
            textField.isSecureTextEntry = false
            textField.isSecureTextEntry = true
        } //End
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    // MARK: Observer
    
    override func keyboardWillShowNotification(_ notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        let keyboardInfoKey = notification.userInfo![UIKeyboardFrameEndUserInfoKey]
        
        if keyboardInfoKey != nil {
            let keyboardHeight = (keyboardInfoKey as! NSValue).cgRectValue.size.height
            
            let contentInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardHeight, right: 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
            if let bottomView = bottomButtonContainer {
                bottomView.frame.originY = confirmButtonOriginalY - keyboardHeight + tabBarHeight
            }
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.contentInset = UIEdgeInsets.zero
        collectionView.scrollIndicatorInsets = UIEdgeInsets.zero
        
        if let bottomView = bottomButtonContainer {
            bottomView.frame.originY = confirmButtonOriginalY
        }
    }
    
}
