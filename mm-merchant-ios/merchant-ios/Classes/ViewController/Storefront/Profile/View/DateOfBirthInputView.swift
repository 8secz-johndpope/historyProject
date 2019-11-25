//
//  DateOfBirthInputView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 3/21/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

import UIKit

protocol DateOfBirthInputViewProtocol: NSObjectProtocol{
    func didUpdateDateOfBirth(_ date: Date?, closePickerView: Bool)
}

class DateOfBirthInputView: UIView {
    
    var datePicker: UIDatePicker!
    private var doneButton: UIButton!
    
    weak var delegate: DateOfBirthInputViewProtocol?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupSubViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupSubViews() {
        doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: frame.size.width - 60, y: 10, width: 50, height: 30)
        doneButton.setTitle(String.localize("LB_DONE"), for: UIControlState())
        doneButton.setTitleColor(UIColor.redDoneButton(), for: UIControlState())
        doneButton.addTarget(self, action: #selector(DateOfBirthInputView.doneAction), for: .touchUpInside)
        addSubview(doneButton)
        
        datePicker = UIDatePicker(frame: CGRect(x: 0, y: 40, width: frame.size.width, height: frame.size.height - 40))
        datePicker.datePickerMode = UIDatePickerMode.date;
        datePicker.maximumDate = Date()
        datePicker.addTarget(self, action: #selector(DateOfBirthInputView.datePickerValueChanged), for: .valueChanged)
        addSubview(datePicker)
    }
    
    @objc func doneAction(_ sender: UIButton!) {
        self.delegate?.didUpdateDateOfBirth(self.datePicker.date, closePickerView: true)
    }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker!) {
        self.delegate?.didUpdateDateOfBirth(self.datePicker.date, closePickerView: false)
    }
}
