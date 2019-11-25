//
//  ConfirmResetPasswordViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 4/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
import ObjectMapper

class ConfirmResetPasswordViewController : UIViewController{
    
    var userKey : String?
    var activationToken : String?

    @IBOutlet weak var confirmPasswordLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBAction func confirmClicked(_ sender: Any) {
        if passwordTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("MSG_ERR_RESET_PASSWORD_NIL"))
            return
        }
        if confirmPasswordTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("MSG_ERR_RESET_PASSWORD_REENTER_NIL"))
            return
        }
        if passwordTextField.text?.isValidPassword() == false {
            self.showErrorAlert(String.localize("LB_PASSWORD_CHARACTER"))
            return
        }
        if passwordTextField.text != confirmPasswordTextField.text{
            self.showErrorAlert(String.localize("MSG_ERR_PASSWORD_REENTER_NOT_MATCH"))
            return
        }

//        let parameters : [String : Any] = ["ActivationToken" : self.activationToken!, "UserKey" : self.userKey!, "Password" : passwordTextField.text!]
//        AuthService.activateCode(parameters){[weak self] (response) in
//            if let strongSelf = self {
//                if response.result.isSuccess {
//                    strongSelf.stopLoading()
//                    
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
//                        strongSelf.stopLoading()
//                        strongSelf.handleApiResponseError(response)
//                    }
//                } else {
//                    strongSelf.stopLoading()
//                    strongSelf.showErrorAlert(String.localize("MSG_ERR_NETWORK_FAIL"))
//                }
//            }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.primary2()
        self.passwordTextField.format()
        self.confirmPasswordTextField.format()
        self.confirmButton.formatPrimary()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_RESET_PW_USER")
        self.confirmPasswordLabel.text = String.localize("LB_PASSWORD_CHARACTER")
        self.passwordTextField.placeholder = String.localize("LB_PASSWORD")
        self.confirmPasswordTextField.placeholder = String.localize("LB_REENTER_PASSWORD")
        self.confirmButton.setTitle(String.localize("LB_CONFIRM"), for: UIControlState())
    }
}
