//
//  RequestInvitationCodeView.swift
//  merchant-ios
//
//  Created by LongTa on 7/18/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class RequestInvitationCodeView: UIView {

    let viewInvitationCode = UIView()
    static let viewInvitationCodeHeight = CGFloat(46)
    static let viewInvitationCodeTopPadding = CGFloat(25)
    static let viewInvitationCodeBottomPadding = CGFloat(8)

    static let viewInvitationCodeLeftRightPadding = CGFloat(12)
    static let imageViewFlagLeftRightPadding = CGFloat(10)

    let textFieldInvitationName = UITextField()
    
    let labelNote = UILabel()
    static let labelNoteTopPadding = CGFloat(100)
    static let labelNoteSize = CGSize(width: 261, height: 40)
    
    let viewMobileNo = UIView()
    
    let textFieldMobileNo = UITextField()
    static let textFieldMobileNoLeftRightPadding = CGFloat(15)

    let textFieldCountryCode = UITextField()
    
    let buttonSelectPhoneFormat = UIButton()
    
    let imageViewFlag = UIImageView()
    static let imageViewFlagSize = CGSize(width: 30, height: 21)
    
    let imageViewArrowDown = UIImageView()
    static let imageViewArrowDown = CGSize(width: 5, height: 5)
    
    let buttonConfirm = UIButton()
    static let buttonConfirmTopPadding = CGFloat(28)
    static let buttonConfirmHeight = CGFloat(42)
    
    init() {
        super.init(frame: UIScreen.main.bounds)
        self.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(self.tapToCloseKeyboard)))
    
        labelNote.formatSmall()
        labelNote.textAlignment = .center
        labelNote.text = String.localize("LB_INVITATION_CODE_GET_NOTE")
        addSubview(labelNote)
        
        viewInvitationCode.layer.borderColor = UIColor.secondary1().cgColor
        viewInvitationCode.layer.borderWidth = Constants.TextField.BorderWidth
        viewInvitationCode.layer.cornerRadius = Constants.Button.Radius
        
        addSubview(viewInvitationCode)
        
        textFieldInvitationName.font = UIFont(name: textFieldInvitationName.font!.fontName, size: CGFloat(14))
        textFieldInvitationName.textColor = UIColor.secondary2()
        textFieldInvitationName.placeholder = String.localize("LB_LAUNCH_NAME")
        viewInvitationCode.addSubview(textFieldInvitationName)
        
        
        viewMobileNo.layer.borderColor = UIColor.secondary1().cgColor
        viewMobileNo.layer.borderWidth = Constants.TextField.BorderWidth
        viewMobileNo.layer.cornerRadius = Constants.Button.Radius
        addSubview(viewMobileNo)
        
        textFieldMobileNo.font = UIFont(name: textFieldMobileNo.font!.fontName, size: CGFloat(14))
        textFieldMobileNo.textColor = UIColor.secondary2()
        textFieldMobileNo.placeholder = String.localize("LB_CA_INPUT_MOBILE")
        textFieldMobileNo.keyboardType = UIKeyboardType.phonePad
        viewMobileNo.addSubview(textFieldMobileNo)
        
        buttonSelectPhoneFormat.addTarget(self, action: #selector(RequestInvitationCodeView.selectPhoneFormatButtonClicked), for: .touchUpInside)
        viewMobileNo.addSubview(buttonSelectPhoneFormat)
        
        textFieldCountryCode.isHidden = true
        viewMobileNo.addSubview(textFieldCountryCode)
        
        imageViewFlag.backgroundColor = UIColor.red
        viewMobileNo.addSubview(imageViewFlag)
        
        imageViewArrowDown.image = UIImage(named: "dropDown_arrow")
        viewMobileNo.addSubview(imageViewArrowDown)
        
        buttonConfirm.formatPrimary()
        buttonConfirm.setTitle(String.localize("LB_CA_CONFIRM"), for: UIControlState())
        addSubview(buttonConfirm)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.setupLayouts()
    }
    
    func setupLayouts() {
        
        labelNote.frame = CGRect(x: (self.frame.sizeWidth - RequestInvitationCodeView.labelNoteSize.width)/2, y: RequestInvitationCodeView.labelNoteTopPadding, width: RequestInvitationCodeView.labelNoteSize.width, height: RequestInvitationCodeView.labelNoteSize.height)
        
        viewInvitationCode.frame = CGRect(x: RequestInvitationCodeView.viewInvitationCodeLeftRightPadding, y: labelNote.frame.maxY + RequestInvitationCodeView.viewInvitationCodeTopPadding, width: self.frame.sizeWidth - 2*RequestInvitationCodeView.viewInvitationCodeLeftRightPadding, height: RequestInvitationCodeView.viewInvitationCodeHeight)
        
        textFieldInvitationName.frame = CGRect(x: RequestInvitationCodeView.textFieldMobileNoLeftRightPadding, y: 0, width: viewInvitationCode.frame.sizeWidth - RequestInvitationCodeView.textFieldMobileNoLeftRightPadding - 30, height: viewInvitationCode.frame.sizeHeight)
        
        viewMobileNo.frame = CGRect(x: viewInvitationCode.frame.minX, y: viewInvitationCode.frame.maxY + RequestInvitationCodeView.viewInvitationCodeBottomPadding, width: viewInvitationCode.frame.sizeWidth, height: viewInvitationCode.frame.sizeHeight)
        
        imageViewFlag.frame = CGRect(x: RequestInvitationCodeView.imageViewFlagLeftRightPadding, y: (viewMobileNo.frame.sizeHeight - RequestInvitationCodeView.imageViewFlagSize.height)/2, width: RequestInvitationCodeView.imageViewFlagSize.width, height: RequestInvitationCodeView.imageViewFlagSize.height)
        
        imageViewArrowDown.frame = CGRect(x: imageViewFlag.frame.maxX + RequestInvitationCodeView.viewInvitationCodeLeftRightPadding/2, y: (viewMobileNo.frame.sizeHeight - RequestInvitationCodeView.imageViewArrowDown.height)/2, width: RequestInvitationCodeView.imageViewArrowDown.width, height: RequestInvitationCodeView.imageViewArrowDown.height)
        
        buttonSelectPhoneFormat.frame = CGRect(x: imageViewFlag.frame.minX, y: 0, width: imageViewArrowDown.frame.maxX - imageViewFlag.frame.minX, height: viewMobileNo.frame.sizeHeight)
        textFieldCountryCode.frame = buttonSelectPhoneFormat.frame
        
        textFieldMobileNo.frame = CGRect(x: imageViewArrowDown.frame.maxX + RequestInvitationCodeView.textFieldMobileNoLeftRightPadding, y: 0, width: viewMobileNo.frame.sizeWidth - (imageViewArrowDown.frame.maxX + 2*RequestInvitationCodeView.textFieldMobileNoLeftRightPadding), height: viewMobileNo.frame.sizeHeight)
        
        buttonConfirm.frame = CGRect(x: viewInvitationCode.frame.minX, y: viewMobileNo.frame.maxY + RequestInvitationCodeView.buttonConfirmTopPadding, width: viewInvitationCode.frame.sizeWidth, height: RequestInvitationCodeView.buttonConfirmHeight)
    }
    
    @objc func selectPhoneFormatButtonClicked(){
        Log.debug("Change phone format clicked")
        textFieldCountryCode.becomeFirstResponder()
    }
    
    @objc func tapToCloseKeyboard(){
        self.endEditing(true)
    }
}
