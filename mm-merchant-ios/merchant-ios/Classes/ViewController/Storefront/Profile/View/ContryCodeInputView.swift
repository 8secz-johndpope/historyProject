//
//  ContryCodeInputView.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 8/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class ContryCodeInputView: UIView {
    
    var pickerView : UIPickerView!
    
    private var doneButton: UIButton!
    
    var doneButtonTappedHandler: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        pickerView.delegate = nil
        pickerView.dataSource = nil
        pickerView.showsSelectionIndicator = true
        
        self.addSubview(pickerView)
        
        doneButton = UIButton(type: .system)
        doneButton.frame = CGRect(x: frame.size.width - 60, y: 10, width: 50, height: 30)
        doneButton.setTitle(String.localize("LB_DONE"), for: UIControlState())
        doneButton.setTitleColor(UIColor.redDoneButton(), for: UIControlState())
        doneButton.addTarget(self, action: #selector(ContryCodeInputView.doneAction), for: .touchUpInside)
        addSubview(doneButton)
        
    }
    
    @objc func doneAction(_ sender: UIButton!) {
        if let callback = self.doneButtonTappedHandler{
            callback()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /*
     // Only override drawRect: if you perform custom drawing.
     // An empty implementation adversely affects performance during animation.
     override func drawRect(rect: CGRect) {
     // Drawing code
     }
     */
    
}
