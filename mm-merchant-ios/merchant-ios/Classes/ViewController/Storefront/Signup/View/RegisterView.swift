//
//  RegisterView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 7/20/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class RegisterView: SignupInputView {

    var activeCodeLabel = UILabel()
    var activeCodeView = UIView()
    var activeCodeLineView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        countryLineViewVertical.isHidden = true
        
        inputBackground.layer.borderColor = UIColor.clear.cgColor
        inputBackground.layer.borderWidth = CGFloat(0)
        
        countryLabel.textAlignment = .left
        countryLabel.textColor = UIColor.secondary2()
        countryLabel.applyFontSize(15, isBold: true)
        
        codeTextField.font = countryLabel.font
        
        self.addSubview(activeCodeView)
        activeCodeView.addSubview(activeCodeTextField)
        
        activeCodeLineView.backgroundColor = UIColor.secondary1()
        activeCodeView.addSubview(activeCodeLineView)
        
        
        activeCodeLabel.applyFontSize(15, isBold: true)
        activeCodeLabel.text = String.localize("LB_CA_VERCODE")
        activeCodeLabel.textColor = UIColor.secondary2()
        activeCodeView.addSubview(activeCodeLabel)
        
        activeCodeView.isHidden = true
        
        layout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layout(){
        inputBackground.frame = bounds
        
        let marginLeft = CGFloat(22)
        let paddingTop = CGFloat(5)
        let labelWidth = CGFloat(110)
        countryLabel.frame = CGRect(x: marginLeft, y: 0, width: labelWidth - Constants.TextField.LeftPaddingWidth, height: PhoneNumberHeight)
        countryLineView.frame = CGRect(x: marginLeft / 2, y: PhoneNumberHeight, width: self.frame.width - marginLeft, height: 1)
        
        var width = CGFloat(0)
        if let titleLabel = requestSMSButton.titleLabel {
            width = StringHelper.getTextWidth(titleLabel.text ?? "", height: PhoneNumberHeight, font: titleLabel.font)
            requestSMSButton.frame = CGRect(x: self.bounds.sizeWidth - marginLeft - width, y: PhoneNumberHeight, width: width, height: PhoneNumberHeight)
        }
        
       // let margin = CGFloat(6)
        codeTextField.frame = CGRect(x: marginLeft - Constants.TextField.LeftPaddingWidth, y: PhoneNumberHeight, width: labelWidth, height: PhoneNumberHeight)
        
        phoneLineViewVertical.frame = CGRect(x: codeTextField.frame.maxX, y: PhoneNumberHeight + paddingTop, width: CGFloat(1), height: PhoneNumberHeight - 2 * paddingTop)
        
        borderTF.frame = CGRect(x: marginLeft / 2, y: PhoneNumberHeight + 1, width: self.frame.width - marginLeft, height: PhoneNumberHeight + 1)
        
        countryButton.frame = CGRect(x: countryLabel.frame.maxX + Margin, y: 0, width: bounds.width - (countryLabel.frame.maxX + Margin * 2) , height: PhoneNumberHeight)
        countryTextField.frame = CGRect(x: countryLabel.frame.maxX, y: 0, width: bounds.width - (countryLabel.frame.maxX + Margin), height: PhoneNumberHeight)
        
        let iconSize = CGSize(width: 7, height: 14)
        iconImageView.frame = CGRect(x: self.bounds.sizeWidth - marginLeft - iconSize.width, y: countryTextField.frame.midY - iconSize.height / 2, width: iconSize.width, height: iconSize.height)
        
        mobileNumberTextField.frame = CGRect(x: phoneLineViewVertical.frame.maxX , y: PhoneNumberHeight, width: bounds.width - phoneLineViewVertical.frame.maxX - Margin * 2 - width, height: PhoneNumberHeight)
        
        phoneNumberLineView.frame = CGRect(x: marginLeft/2, y: mobileNumberTextField.frame.maxY, width: self.frame.width - marginLeft, height: 1)
        
        activeCodeView.frame = CGRect(x: 0 , y: phoneNumberLineView.frame.maxY, width: self.frame.width, height: PhoneNumberHeight)
        
        width = StringHelper.getTextWidth(activeCodeLabel.text ?? "", height: activeCodeLabel.frame.sizeHeight, font: activeCodeLabel.font)
        activeCodeLabel.frame = CGRect(x: marginLeft, y: 0, width: width, height: PhoneNumberHeight)
        activeCodeTextField.frame = CGRect(x: activeCodeLabel.frame.maxX , y: 0, width: activeCodeView.frame.sizeWidth - activeCodeLabel.frame.maxX, height: PhoneNumberHeight)
        activeCodeLineView.frame = CGRect(x: marginLeft / 2, y: activeCodeView.frame.height - 1, width: activeCodeView.frame.sizeWidth - marginLeft, height: 1)
        
        activeCodeView.isHidden = (!isCountingDown && !activeCodeView.isHidden)
        
    }
}
