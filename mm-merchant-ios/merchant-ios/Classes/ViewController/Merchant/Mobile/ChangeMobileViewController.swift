//
//  ReactivateMobileViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 5/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class ChangeMobileViewController : UIViewController {
    
    @IBOutlet weak var changeMobileLabel: UILabel!
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var activationCodeTextField: UITextField!
    @IBOutlet weak var reactivateButton: UIButton!
    @IBOutlet weak var resendButton: UIButton!
    
    @IBAction func resendClicked(sender: Any) {
        if self.mobileTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("MSG_ERR_EMAIL_OR_MOBILE_NIL"))
        } else if self.mobileTextField.text?.isValidMMUsername() == false {
            self.showErrorAlert(String.localize("MSG_ERR_FIELDNAME_PATTERN").replacingOccurrences(of: Constants.PlaceHolder.FieldName, with: self.mobileTextField.placeholder!))
        } else {
            self.showLoading()
            let parameters : [String : Any] = ["UserKey" : mobileTextField.text!]
            AuthService.resendCode(parameters){[weak self] (response) in
                if let strongSelf = self {
                    strongSelf.stopLoading()
                    if response.result.isSuccess {
                        if response.response?.statusCode == 200 {
                            strongSelf.showSuccAlert(String.localize("MSG_SUC_RESEND_ACTIVATION_CODE"))
                        } else {
                            strongSelf.handleApiResponseError(response)
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func reactivateClicked(sender: Any) {
        let parameters : [String : Any] = ["ActivationToken" : self.activationCodeTextField.text!, "UserKey" : self.mobileTextField.text!]
        AuthService.reactivateCode(parameters){ response in
            if response.response?.statusCode == 200 {
                SettingViewController.logout()
            }
        }
    }
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.primary2()
        self.changeMobileLabel.format()
        self.mobileTextField.format()
        self.activationCodeTextField.format()
        self.reactivateButton.formatPrimary()
        self.resendButton.formatSecondary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = String.localize("LB_CHANGE_MOBILE")
        self.changeMobileLabel.text = String.localize("LB_COMPLETE_REGISTRATION_NOTE")
        self.mobileTextField.placeholder = String.localize("LB_MOBILE")
        self.activationCodeTextField.placeholder = String.localize("LB_ACTIVATION_CODE")
        self.reactivateButton.setTitle(String.localize("LB_CONFIRM"), for: .normal)
        self.resendButton.setTitle(String.localize("LB_RESEND_ACTIVATION_CODE"), for: .normal)

    }

    
}
