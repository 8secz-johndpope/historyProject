//
//  RegistrationViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 19/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class RegisterViewController : UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var hintTextLabel: UILabel!
    @IBOutlet weak var activationCodeTextField: UITextField!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var resendHintLabel: UILabel!
    @IBOutlet weak var userNameTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.primary2()
        hintTextLabel.format()
        userNameTextField.format()
        activationCodeTextField.format()
        nextButton.formatPrimary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_COMPLETE_REGISTRATION")
        self.userNameTextField.placeholder = String.localize("LB_EMAIL_OR_MOBILE")
        self.activationCodeTextField.placeholder = String.localize("LB_ACTIVATION_CODE")
        self.hintTextLabel.text = String.localize("LB_COMPLETE_REGISTRATION_NOTE")
        self.nextButton.setTitle(String.localize("LB_NEXT"), for: UIControlState())
        self.resendButton.setTitle(String.localize("LB_RESEND_ACTIVATION_CODE"), for: UIControlState())
        self.resendHintLabel.text = String.localize("LB_ACTIVATION_CODE_3TIMES")
    }
    
    func verifyUsername() -> Bool {
        var res : Bool = true
        if userNameTextField.text?.length == 0 {
            res = false
            self.showErrorAlert(String.localize("MSG_ERR_EMAIL_OR_MOBILE_NIL"))
        } else {
            if self.userNameTextField.text?.isValidMMUsername() == false {
                res = false
                self.showErrorAlert(String.localize("MSG_ERR_FIELDNAME_PATTERN").replacingOccurrences(of: Constants.PlaceHolder.FieldName, with: self.userNameTextField.placeholder!))
            }
        }
        return res
    }
    
    func verifyActivationCode() -> Bool {
        if activationCodeTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("LB_ENTER_ACTIVATION_CODE"))
            return false
        }
        return true
    }
    
    @IBAction func nextButtonClicked(_ sender: Any) {
        if verifyUsername() && verifyActivationCode() {
			self.showLoading()
//            let parameters : [String : Any] = ["UserKey" : userNameTextField.text!, "ActivationToken" : activationCodeTextField.text!]
//            AuthService.validateCode(parameters){[weak self] (response) in
//                if let strongSelf = self {
//                    strongSelf.stopLoading()
//                    Log.debug(response.response?.statusCode)
//                    if response.result.isSuccess {
//                        if response.response?.statusCode == 200 {
//                            let confirmPasswordViewController = UIStoryboard(name: "Register", bundle: nil).instantiateViewControllerWithIdentifier("CreatePasswordViewController") as! CreatePasswordViewController
//                            confirmPasswordViewController.userKey = strongSelf.userNameTextField.text!
//                            confirmPasswordViewController.activationToken = strongSelf.activationCodeTextField.text!
//                            strongSelf.navigationController?.pushViewController(confirmPasswordViewController, animated: true)
//                        } else {
//                            strongSelf.handleApiResponseError(response)
//                        }
//                    }
//                }
//            }
        }
    }

    @IBAction func resendButtonClicked(_ sender: Any) {
        if verifyUsername() {
            self.showLoading()
//            let parameters : [String : Any] = ["UserKey" : userNameTextField.text!]
//            AuthService.resendCode(parameters){[weak self] (response) in
//                if let strongSelf = self {
//                    strongSelf.stopLoading()
//                    if response.result.isSuccess {
//                        if response.response?.statusCode == 200 {
//                            strongSelf.showSuccAlert(String.localize("MSG_SUC_RESEND_ACTIVATION_CODE"))
//                        } else {
//                            strongSelf.handleApiResponseError(response)
//                        }
//                    }
//                }
//            }
        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
