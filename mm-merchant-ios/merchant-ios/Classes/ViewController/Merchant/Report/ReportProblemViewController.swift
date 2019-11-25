//
//  ReportProblemViewController.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 4/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class ReportProblemViewController : UIViewController{
    
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    
    var user : User?

    @IBAction func sendClicked(_ sender: Any) {
    }
    
    override func viewDidLoad() {
        subjectTextField.format()
        sendButton.formatPrimary()
        messageTextView.format()
        self.view.backgroundColor = UIColor.primary2()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.title = String.localize("LB_REPORT_PROBLEM")
        self.subjectTextField.placeholder = String.localize("LB_SUBJECT")
        self.sendButton.setTitle(String.localize("LB_SEND"), for: UIControlState())
    }
}
