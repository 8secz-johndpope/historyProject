//
//  AfterSalesReasonInputView.swift
//  merchant-ios
//
//  Created by Quang Truong Dinh on 4/1/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class AfterSalesReasonInputView: UIView {
    
    static let DefaultHeight: CGFloat = 206
    
    var pickerView : UIPickerView!
    
    private var doneButton: UIButton!
    
    var didPressDone: (()->())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: frame.size.width - 60, y: 10, width: 50, height: 30)
        doneButton.setTitle(String.localize("LB_DONE"), for: UIControlState())
        doneButton.setTitleColor(UIColor.redDoneButton(), for: UIControlState())
        doneButton.addTarget(self, action: #selector(DateOfBirthInputView.doneAction), for: .touchUpInside)
        addSubview(doneButton)
        
        pickerView = UIPickerView(frame: CGRect(x: 0, y: 40, width: frame.size.width, height: frame.size.height - 40))
        pickerView.delegate = nil
        pickerView.dataSource = nil
        pickerView.showsSelectionIndicator = true
        
        self.addSubview(pickerView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   @objc func doneAction(_ sender: UIButton!) {
        if let action = self.didPressDone {
            action()
        } else {
            ErrorLogManager.sharedManager.recordNonFatalError(withException: .NullPointer)
        }
    }
    
}
