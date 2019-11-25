//
//  UserNameSettingViewController.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit
import ObjectMapper

class UserNameSettingViewController: MmViewController, UIGestureRecognizerDelegate, UITextFieldDelegate {
    
    private var userNameTextField: UITextField!
    private var passwordTextField: UITextField!
    
    var user = User()
    var isDisappear = false
    
    private var confirmButtonOriginalY: CGFloat = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = String.localize("LB_CA_USERNAME")
        
		setupDismissKeyboardGesture()
		
		createBackButton()
		createBottomButton(String.localize("LB_CA_CONFIRM"), customAction: #selector(UserNameSettingViewController.confirm(_:)))
		setupSubViews()
		retrieveUser()
	}
    
    override func shouldHideTabBar() -> Bool {
        return true
    }
    
    //MARK: - View Creating
    
    func setupSubViews() {
        let cellHeight: CGFloat = 64
        let marginHorizontal: CGFloat = 11
        let marginVertical: CGFloat = 9
		let navBarHeightWithPadding: CGFloat = 109 // 64 + 10 + 35 (extra space for error message pop up)
        let textFieldHeight = cellHeight - (marginVertical * 2)
        
        userNameTextField = UITextField(frame: CGRect(x:marginHorizontal, y: navBarHeightWithPadding + marginVertical, width: view.width - 2 * marginHorizontal, height: textFieldHeight))
        userNameTextField.format()
        userNameTextField.placeholder = String.localize("LB_CA_USERNAME")
        userNameTextField.delegate = self
        userNameTextField.returnKeyType = .Next
        userNameTextField.addTarget(self, action: #selector(UserNameSettingViewController.editingDidEndOnExit(_:)), forControlEvents: .EditingDidEndOnExit)
        
        userNameTextField.addTarget(self, action: #selector(UserNameSettingViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        
        view.addSubview(userNameTextField)
        
        passwordTextField = UITextField(frame: CGRect(x:marginHorizontal, y: (navBarHeightWithPadding + marginVertical) + textFieldHeight + marginVertical, width: view.width - (2 * marginHorizontal), height: textFieldHeight))
        passwordTextField.format()
        passwordTextField.placeholder = String.localize("LB_CA_ENTER_PW")
        passwordTextField.secureTextEntry = true
        passwordTextField.delegate = self
        passwordTextField.addTarget(self, action: #selector(UserNameSettingViewController.editingDidEndOnExit(_:)), forControlEvents: .EditingDidEndOnExit)
        
        passwordTextField.addTarget(self, action: #selector(UserNameSettingViewController.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
        passwordTextField.returnKeyType = .Done
        view.addSubview(passwordTextField)
        
        if let view = bottomButtonContainer {
            confirmButtonOriginalY = view.frame.origin.y
        }
    }

	//MARK: - UITextField Delegate
    func editingDidEndOnExit(textField: UITextField) {
        
        if textField == userNameTextField {
            passwordTextField.becomeFirstResponder()
        } else {
            self.dismissKeyboardFromView()
        }
        
    }
    
    func textFieldDidChange(textField: UITextField) {
        
        textField.setStyleDefault()
        
    }
    
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        isDisappear = true
        self.dismissKeyboardFromView()
    }

    
    
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    

    
    func textFieldShouldClear(textField: UITextField) -> Bool {
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        return true
    }
    
    func highLightTextField(textField: UITextField, message: String)  {
        
        showError(message, animated: true)
        textField.shouldHighlight(true)
        textField.becomeFirstResponder()
        
    }
    func confirm(button: UIButton) {
        guard userNameTextField.text != "" else {
            highLightTextField(userNameTextField, message: String.localize("MSG_ERR_CA_USERNAME_NIL"))
            return
        }
        
        
        
        if !userNameTextField.text!.isValidUserName() {
            
            highLightTextField(userNameTextField, message: String.localize("MSG_ERR_CA_USERNAME_PATTERN"))
            
            return
        }
        userNameTextField.shouldHighlight(false)
        
        guard passwordTextField.text != "" else {
            
            highLightTextField(passwordTextField, message: String.localize("MSG_ERR_CA_PW_NIL"))
            
            return
        }
		
        firstly {
            return changeUserName(userNameTextField.text!, password: passwordTextField.text!)
        }.then { _ -> Void in
            self.navigationController?.popViewController(animated:true)
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
    
    func fetchUser() -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.view() { [weak self] (response) in
                if let strongSelf = self {
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.user = Mapper<User>().map(JSONObject: response.result.value) ?? User()
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
        userNameTextField.text = user.userName
    }
    
    func changeUserName(userName: String, password: String) -> Promise<Any> {
        return Promise { fulfill, reject in
            UserService.changeUserName(userName, password: password, completion: { [weak self] (response) -> Void in
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
    
    // MARK: Observer
    
    override func keyboardWillShowNotification(notification: NSNotification) {
        super.keyboardWillShowNotification(notification)
        
        let keyboardInfoKey = notification.userInfo![UIKeyboardFrameEndUserInfoKey]
        
        if keyboardInfoKey != nil {
            let keyboardHeight = keyboardInfoKey!.CGRectValue.size.height
            
            let contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardHeight, 0.0)
            
            collectionView.contentInset = contentInsets
            collectionView.scrollIndicatorInsets = contentInsets
            
            if let bottomView = bottomButtonContainer {
                bottomView.frame.originY = confirmButtonOriginalY - keyboardHeight + tabBarHeight
            }
        }
    }
    
    override func keyboardWillHideNotification(_ notification: NSNotification) {
        super.keyboardWillHideNotification(notification)
        
        collectionView.contentInset = UIEdgeInsetsZero
        collectionView.scrollIndicatorInsets = UIEdgeInsetsZero
        
        if let bottomView = bottomButtonContainer {
            bottomView.frame.originY = confirmButtonOriginalY
        }
    }
}
