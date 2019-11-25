//
//  ResetPasswordController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 4/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class ResetPasswordViewController : UIViewController{
    
    var userKey : String?
    
    @IBOutlet weak var resetPasswordLabel: UILabel!
    @IBOutlet weak var mobileNumberTextField: UITextField!
    @IBOutlet weak var activationCodeTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var resendActivationCodeButton: UIButton!
    
    @IBAction func nextClicked(_ sender: Any) {
        if activationCodeTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("LB_ENTER_ACTIVATION_CODE"))
            return
        }

        self.showLoading()
//        let parameters : [String : Any] = ["UserKey" : mobileNumberTextField.text!, "ActivationToken" : activationCodeTextField.text!]
//        AuthService.validateCode(parameters){[weak self] (response) in
//            if let strongSelf = self {
//                strongSelf.stopLoading()
//                if response.result.isSuccess {
//                    if response.response?.statusCode == 200 {
//                        let confirmResetPasswordViewController = UIStoryboard(name: "Password", bundle: nil).instantiateViewControllerWithIdentifier("ConfirmResetPasswordViewController") as! ConfirmResetPasswordViewController
//                        confirmResetPasswordViewController.userKey = strongSelf.mobileNumberTextField.text
//                        confirmResetPasswordViewController.activationToken = strongSelf.activationCodeTextField.text
//                        strongSelf.navigationController?.pushViewController(confirmResetPasswordViewController, animated: true)
//                    } else {
//                        strongSelf.handleApiResponseError(response)
//                    }
//                }
//            }
//        }
    }

    @IBAction func resendClicked(_ sender: Any) {
        self.showLoading()
//        let parameters : [String : Any] = ["UserKey" : self.mobileNumberTextField.text!]
//        AuthService.resendCode(parameters){[weak self] (response) in
//            if let strongSelf = self {
//                strongSelf.stopLoading()
//                if response.result.isSuccess {
//                    if response.response?.statusCode == 200 {
//                        strongSelf.showSuccAlert(String.localize("MSG_SUC_RESEND_ACTIVATION_CODE"))
//                    } else {
//                        strongSelf.handleApiResponseError(response)
//                    }
//                }
//            }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.primary2()
        resetPasswordLabel.format()
        mobileNumberTextField.format()
        activationCodeTextField.format()
        nextButton.formatPrimary()
        resendActivationCodeButton.formatSecondary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_RESET_PW_USER")
        self.resetPasswordLabel.text = String.localize("LB_COMPLETE_REGISTRATION_NOTE")
        self.mobileNumberTextField.placeholder = String.localize("LB_MOBILE")
        self.activationCodeTextField.placeholder = String.localize("LB_ACTIVATION_CODE")
        self.nextButton.setTitle(String.localize("LB_NEXT"), for: UIControlState())
        self.resendActivationCodeButton.setTitle(String.localize("LB_RESEND_ACTIVATION_CODE"), for: UIControlState())
        if self.userKey != nil{
            // lock the mobile number field
            self.mobileNumberTextField.isUserInteractionEnabled = false
            self.mobileNumberTextField.text = self.userKey
        }
    }
}
