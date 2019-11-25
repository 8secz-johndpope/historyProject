//
//  NameViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 14/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class NameViewController : UIViewController{
    weak var delegate : ChangeNameDelegate?
    
    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var middleNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var displayNameTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    // title label
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var middleNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    
    @IBAction func confirmClicked(sender: Any) {
        if firstNameTextField.text?.length < 1 || firstNameTextField.text?.length > 50 {
            self.showErrorAlert(String.localize("MSG_ERR_MERCHANT_FIRSTNAME"))
            return
        } else if middleNameTextField.text?.length < 1 || middleNameTextField.text?.length > 50 {
            self.showErrorAlert(String.localize("MSG_ERR_MERCHANT_MIDDLENAME"))
            return
        } else if lastNameTextField.text?.length < 1 || lastNameTextField.text?.length > 50 {
            self.showErrorAlert(String.localize("MSG_ERR_MERCHANT_LASTNAME"))
            return
        } else if displayNameTextField.text?.length < 3 || displayNameTextField.text?.length > 25 {
            // RID_TB_MERCHANT_PROFILE_DISP_NAME
            self.showErrorAlert(String.localize("MSG_ERR_MERCHANT_DISP_NAME"))
            return
        }
        self.user!.firstName = firstNameTextField.text!
        self.user!.middleName = middleNameTextField.text!
        self.user!.lastName = lastNameTextField.text!
        self.user!.displayName = displayNameTextField.text!
        delegate?.changeName(self.user!)
        self.navigationController!.popViewController(animated:true)
    }
    
    var user : User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.primary2()
        firstNameTextField.format()
        middleNameTextField.format()
        lastNameTextField.format()
        displayNameTextField.format()
        confirmButton.formatPrimary()
        cancelButton.formatSecondary()
        firstNameTextField.text = self.user!.firstName
        middleNameTextField.text = self.user!.middleName
        lastNameTextField.text = self.user!.lastName
        displayNameTextField.text = self.user!.displayName
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_NAME")
        self.firstNameLabel.text = String.localize("LB_FIRSTNAME")
        self.middleNameLabel.text = String.localize("LB_MIDDLE_NAME")
        self.lastNameLabel.text = String.localize("LB_LASTNAME")
        self.displayNameLabel.text = String.localize("LB_DISP_NAME")
        self.confirmButton.setTitle(String.localize("LB_CONFIRM"), for: UIControlState.normal)
        self.cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState.normal)
    }

    @IBAction func cancelClicked(sender: Any) {
        self.navigationController!.popViewController(animated:true)
    }
}
