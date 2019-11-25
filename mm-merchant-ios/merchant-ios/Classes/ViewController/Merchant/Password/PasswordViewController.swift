//
//  PasswordViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 29/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class PassWordViewController : UIViewController{
    weak var delegate : ChangePasswordDelegate?
    var user : User?
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!

    @IBAction func cancelButtonClicked(sender: Any) {
        self.navigationController!.popViewController(animated:true)
    }
    @IBOutlet weak var oldPassWordTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBAction func confirmButtonClicked(sender: Any) {
        if oldPassWordTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("MSG_ERR_RESET_OLD_PASSWORD_NIL"))
            return
        }
        if newPasswordTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("MSG_ERR_RESET_PASSWORD_NIL"))
            return
        }
        if confirmPasswordTextField.text?.length == 0 {
            self.showErrorAlert(String.localize("MSG_ERR_RESET_PASSWORD_REENTER_NIL"))
            return
        }
        if newPasswordTextField.text?.isValidPassword() == false {
            self.showErrorAlert(String.localize("LB_PASSWORD_CHARACTER"))
            return
        }
        if newPasswordTextField.text != confirmPasswordTextField.text {
            self.showErrorAlert(String.localize("MSG_ERR_PASSWORD_REENTER_NOT_MATCH"))
            return
        }

        self.user!.password = self.confirmPasswordTextField.text!
        self.user!.passwordOld = self.oldPassWordTextField.text!
        self.delegate?.changePassword(self.user!)
        self.navigationController!.popViewController(animated:true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.view.backgroundColor = UIColor.primary2()
        self.oldPassWordTextField.format()
        self.newPasswordTextField.format()
        self.confirmPasswordTextField.format()
        self.confirmButton.formatPrimary()
        self.cancelButton.formatSecondary()
        
#if (arch(i386) || arch(x86_64)) && os(iOS) // TARGET_IPHONE_SIMULATOR
        self.oldPassWordTextField.secureTextEntry = false
        self.newPasswordTextField.secureTextEntry = false
        self.confirmPasswordTextField.secureTextEntry = false
#endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_CHANGE_PASSWORD")
        self.oldPassWordTextField.placeholder = String.localize("LB_OLD_PASSWORD")
        self.newPasswordTextField.placeholder = String.localize("LB_NEW_PASSWORD")
        self.confirmPasswordTextField.placeholder = String.localize("LB_CONF_NEW_PASSWORD")
        self.confirmButton.setTitle(String.localize("LB_CONFIRM"), for: UIControlState.normal)
        self.cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState.normal)
    }
}
