//
//  MobileViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 16/10/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

protocol SelectCountryDelegate: NSObjectProtocol{
    func selectCountry(_ country : Country)
    func selectMobileCode(_ mobilecode : MobileCode)
}

class MobileViewController : UIViewController, SelectCountryDelegate{
    
    weak var delegate : ChangeMobileDelegate?
    
    @IBOutlet weak var currentMobile: UILabel!
    @IBOutlet weak var countryCodeTextField: UITextField!
    @IBOutlet weak var mobileTextField: UITextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var countryButton: UIButton!
    var user : User?
    @IBAction func confirmClicked(_ sender: Any) {
//        if mobileTextField.text?.isNumberic() == false {
        if (countryCodeTextField.text! + mobileTextField.text!).isValidPhone() == false{
            self.showErrorAlert(String.localize("MSG_ERR_MOBILE_PATTERN"))
            return
        }
        self.user!.mobileCode = countryCodeTextField.text!
        self.user!.mobileNumber = mobileTextField.text!
        delegate?.changeMobile(self.user!)
        self.navigationController!.popViewController(animated: true)
    }
    @IBAction func cancelClicked(_ sender: Any) {
        self.navigationController!.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentMobile.format()
        self.view.backgroundColor = UIColor.primary2()
        countryCodeTextField.format()
        mobileTextField.format()
        confirmButton.formatPrimary()
        cancelButton.formatSecondary()
        countryButton.formatSecondary()
        
        // localization
        countryButton.setTitle(String.localize("LB_COUNTRY_PICK"), for: UIControlState())
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // localization
        self.title = String.localize("LB_CHANGE_MOBILE")
        let txt = String.localize("LB_CURRENT_MOBILE").replacingOccurrences(of: Constants.PlaceHolder.CurrentMobileNumber, with:"")
        self.currentMobile.text = txt + (self.user?.mobileCode)! + " " + (self.user?.mobileNumber)!
        self.mobileTextField.placeholder = String.localize("LB_NEW_MOBILE")
        self.confirmButton.setTitle(String.localize("LB_CONFIRM"), for: UIControlState())
        self.cancelButton.setTitle(String.localize("LB_CANCEL"), for: UIControlState())
    }
    

    @IBAction func countryButtonClicked(_ sender: Any) {
        let selectCountryViewController = UIStoryboard(name: "Setting", bundle: nil).instantiateViewController(withIdentifier: "SelectCountryViewController") as! SelectCountryViewController
        selectCountryViewController.delegate = self
        self.navigationController?.push(selectCountryViewController, animated: true)
    }
    
    func selectCountry(_ country: Country) {
        countryCodeTextField.text = "+" + country.callingCodes[0]
        countryButton.setTitle(country.name, for: UIControlState())
    }
    
    func selectMobileCode(_ mobilecode: MobileCode) {
        countryCodeTextField.text = mobilecode.mobileCodeNameInvariant
        countryButton.setTitle(mobilecode.mobileCodeName, for: UIControlState())
    }
    
}
