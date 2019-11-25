//
//  EmailViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 15/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class EmailViewController : UIViewController{
    
    weak var delegate : ChangeEmailDelegate?
    var user : User?
    
    @IBOutlet weak var currentEmailLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var confirmEmailTextField: UITextField!
    @IBOutlet weak var newEmailTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.primary2()
        newEmailTextField.format()
        confirmEmailTextField.format()
        confirmButton.formatPrimary()
        cancelButton.formatSecondary()
        currentEmailLabel.format()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_CHANGE_EMAIL")
        let txt = String.localize("LB_CURRENT_EMAIL").replacingOccurrences(of: Constants.PlaceHolder.CurrentEmail, with: "")
        self.currentEmailLabel.text = txt + (self.user?.email)!
        self.newEmailTextField.placeholder = String.localize("LB_NEW_EMAIL")
        self.confirmEmailTextField.placeholder = String.localize("LB_CONF_NEW_EMAIL")
        self.confirmButton.setTitle(String.localize("LB_CONFIRM"), for: UIControlState.normal)
        self.cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState.normal)
        
    }
    
    @IBAction func confirmClicked(sender: Any) {
        if newEmailTextField.text?.isValidEmail() == false {
            self.showErrorAlert(String.localize("MSG_ERR_EMAIL_PATTERN"))
            return
        }
        if confirmEmailTextField.text != newEmailTextField.text {
            self.showErrorAlert(String.localize("MSG_ERR_EMAIL_NOT_MATCH"))
            return
        }
        self.user!.email = confirmEmailTextField.text!
        delegate?.changeEmail(self.user!)

        self.navigationController!.popViewController(animated:true)
    }
    @IBAction func cancelClicked(sender: Any) {
        self.navigationController!.popViewController(animated:true)
    }
}
