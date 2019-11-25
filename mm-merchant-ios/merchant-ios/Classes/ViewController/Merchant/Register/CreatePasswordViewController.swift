//
//  CreatePasswordViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 19/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class CreatePasswordViewController : UIViewController, UITextFieldDelegate {
    
    var userKey : String?
    var activationToken : String?
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var hintLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.primary2()
        passwordTextField.format()
        confirmPasswordTextField.format()
        confirmButton.formatPrimary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_COMPLETE_REGISTRATION")
        self.hintLabel.text = String.localize("LB_PASSWORD_CHARACTER")
        self.passwordTextField.placeholder = String.localize("LB_PASSWORD")
        self.confirmPasswordTextField.placeholder = String.localize("LB_ENTER_PASSWORD")
        self.confirmButton.setTitle(String.localize("LB_CONFIRM"), for: UIControlState())
    }
    
    @IBAction func confirmButtonClicked(_ sender: Any) {
        if passwordTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("MSG_ERR_RESET_PASSWORD_NIL"))
            return
        }
        if confirmPasswordTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("MSG_ERR_RESET_PASSWORD_REENTER_NIL"))
            return
        }
        if passwordTextField.text?.isValidPassword() == false {
            self.showErrorAlert(String.localize("MSG_ERR_FIELDNAME_PATTERN").replacingOccurrences(of: Constants.PlaceHolder.FieldName, with: self.passwordTextField.placeholder!))
            return
        }
        if passwordTextField.text != confirmPasswordTextField.text {
            self.showErrorAlert(String.localize("MSG_ERR_PASSWORD_REENTER_NOT_MATCH"))
            return
        }
        
        self.showLoading()
    
//        let parameters : [String : Any] = ["ActivationToken" : self.activationToken!, "UserKey" : self.userKey!, "Password" : passwordTextField.text!]
//        AuthService.activateCode(parameters){[weak self] (response) in
//            if let strongSelf = self {
//                strongSelf.stopLoading()
//                
//                if response.result.isSuccess {
//                    if response.response!.statusCode == 200 {
//                        let token = Mapper<Token>().map(JSONObject: response.result.value)
//                        let tokenString = token?.token
//                        let userId = token?.userId
//                        Context.setToken(tokenString!)
//                        Context.setUserId(userId!)
//                        Context.setUsername(strongSelf.userKey!)
//                        Context.setPassword(strongSelf.passwordTextField.text!)
//                        Context.setAuthenticatedUser(true)
//                        
//                        MobClick.profileSignInWithPUID(strongSelf.userKey)
//                        let userViewController = UIStoryboard(name: "User", bundle: nil).instantiateViewControllerWithIdentifier("UserViewController")
//                        strongSelf.navigationController?.setViewControllers([userViewController], animated: true)
//                    } else {
//                        strongSelf.handleApiResponseError(response)
//                    }
//                } else {
//                    strongSelf.stopLoading()
//                    strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_FAIL"))
//                }
//            }
//        }
    }
    
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
