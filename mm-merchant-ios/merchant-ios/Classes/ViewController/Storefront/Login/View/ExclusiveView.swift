//
//  ExclusiveView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/15/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
private func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class ExclusiveView: UIView {
    private let backgroundImageView = UIImageView()
    private var labelTop = UILabel()
    var viewContent = UIView()
    private var viewInput = UIView()
    private var viewInputOverlay : VisualEffectView!
    var textFieldInviteCode = UITextField()
    var buttonConfirm = CircularProgressButton()
    var buttonInvite = UIButton()
    
    let guestButton = UIButton()
    
        private final let MarginLeftRight : CGFloat = 10
    private final let LabelHeight : CGFloat = 44
    private final let ButtonHeight : CGFloat = 44
    private final let ButtonInviteWidth : CGFloat = 200
    private final let Spacing : CGFloat = 15
    let logoIcon = UIImageView()
    private final let logoIconPaddingBottom:CGFloat = 58
    private final let logoIconSize = CGSize(width: 90, height: 110)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundImageView.image = UIImage(named: "exclusive-bg")
        self.addSubview(backgroundImageView)
        logoIcon.image = UIImage(named: "exclusive_icon_title")
        logoIcon.contentMode = .scaleAspectFill
        self.viewContent.addSubview(logoIcon)
        labelTop.formatSmall()
        labelTop.textColor = UIColor.white
        labelTop.text = String.localize("LB_EXCL_STARTPAGE_INV_CODE_DESC")
        labelTop.textAlignment = .center
        self.viewContent.addSubview(labelTop)
        self.viewContent.backgroundColor = UIColor.clear
        viewInput.backgroundColor = UIColor.clear
        viewInput.layer.cornerRadius = Constants.Button.Radius
        viewInput.layer.borderColor = UIColor.secondary3().cgColor
        viewInput.layer.borderWidth = 1.0
        viewInput.clipsToBounds = true
        self.viewContent.addSubview(viewInput)
        viewInputOverlay = VisualEffectView()
        viewInputOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        viewInputOverlay.alpha = 0.8
        viewInputOverlay.backgroundColor = UIColor.clear
        viewInputOverlay.tint(UIColor.white, blurRadius: 6)
        self.viewInput.addSubview(viewInputOverlay)
        textFieldInviteCode.formatTransparent()
        textFieldInviteCode.textColor = UIColor.white
        textFieldInviteCode.textAlignment = .center
        textFieldInviteCode.clearButtonMode = .whileEditing
        textFieldInviteCode.autocorrectionType = .no
        textFieldInviteCode.autocapitalizationType = .none
        textFieldInviteCode.keyboardType = .asciiCapable
        
        self.clearPlaceHolder(false)
        self.viewInput.addSubview(textFieldInviteCode)
        buttonConfirm.formatTransparent()
        buttonConfirm.setTitle(String.localize("LB_CA_SUBMIT"), for: UIControlState())
        buttonConfirm.isEnabled = false
        self.viewContent.addSubview(buttonConfirm)
        
        
        guestButton.setTitle(String.localize("LB_CA_GUEST_LOGIN"), for: UIControlState())
        guestButton.setTitleColor(UIColor.white, for: UIControlState())
        guestButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        guestButton.viewBorder(UIColor.white)
        guestButton.round(2)
        self.viewContent.addSubview(guestButton)
        
//        buttonInvite.setTitle(String.localize("LB_LAUNCH_INVITATION_CODE_GET"), for: UIControlState.normal)
        self.setInviteButtonTitle()
        buttonInvite.titleLabel?.formatSmall()
        buttonInvite.setTitleColor(UIColor.white, for: UIControlState())
        self.viewContent.addSubview(buttonInvite)
        self.addSubview(viewContent)
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.viewContent.frame = self.bounds
        self.backgroundImageView.frame = self.bounds
        
        let bottomAreaHeight : CGFloat = 300
        var startingPointY = self.bounds.height / 2
        startingPointY = startingPointY + bottomAreaHeight > self.bounds.height ? self.bounds.height - bottomAreaHeight : startingPointY
            
            
        self.labelTop.frame = CGRect(x: 0, y: startingPointY - LabelHeight / 2, width: self.bounds.width, height: LabelHeight)
        self.viewInput.frame = CGRect(x: MarginLeftRight, y: labelTop.frame.maxY , width: self.bounds.width - MarginLeftRight * 2, height: ButtonHeight)
        self.textFieldInviteCode.frame = CGRect(x: MarginLeftRight, y: 0 , width: self.viewInput.frame.width - MarginLeftRight * 2, height: self.viewInput.frame.height)
        self.logoIcon.frame = CGRect(x: (self.frame.sizeWidth - logoIconSize.width)/2, y: startingPointY - logoIconPaddingBottom - logoIconSize.height, width: logoIconSize.width, height: logoIconSize.height)
        self.buttonConfirm.frame = CGRect(x: MarginLeftRight, y: viewInput.frame.maxY + Spacing, width: self.bounds.width - MarginLeftRight * 2, height: ButtonHeight)
        self.buttonInvite.frame = CGRect(x: MarginLeftRight, y: buttonConfirm.frame.maxY + 20, width: self.bounds.width - MarginLeftRight * 2, height: ButtonHeight)
        
        guestButton.frame = CGRect(x: (frame.sizeWidth - 160)/2, y: self.buttonInvite.frame.maxY + 15, width: 160, height: 35)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateStatusForConfirmButton(){
        if self.textFieldInviteCode.text?.trim().length > 0 {
            if self.buttonConfirm.currentState == CircularProgressButtonState.normal {
                self.buttonConfirm.formatPrimary()
                self.buttonConfirm.layer.borderWidth = 0
                self.buttonConfirm.isEnabled = true
            }
        } else {
            self.buttonConfirm.formatTransparent()
            self.buttonConfirm.isEnabled = false
        }
    }
    
    func clearPlaceHolder(_ isClear: Bool){
        if isClear {
            textFieldInviteCode.attributedPlaceholder = NSAttributedString(string:"",attributes:[NSAttributedStringKey.foregroundColor: UIColor.white])
        } else {
            textFieldInviteCode.attributedPlaceholder = NSAttributedString(string:String.localize("LB_EXCL_ENTER_INV_CODE_OPTIONAL"),attributes:[NSAttributedStringKey.foregroundColor: UIColor.white])
        }
    }
    
    func setInviteButtonTitle(){
        let title = NSMutableAttributedString()
        let leftFont = UIFont.systemFont(ofSize: 14)
        let rightFont = UIFont.boldSystemFont(ofSize: 14)
        
        
        let leftText = NSAttributedString(
            string: String.localize("LB_LAUNCH_NO_INVITE_CODE"),
            attributes: [
                NSAttributedStringKey.foregroundColor: UIColor.white,
                NSAttributedStringKey.font: leftFont,
            ]
        )
        title.append(leftText)
        let rightText = NSAttributedString(
            string: String.localize("LB_LAUNCH_INVITATION_CODE_GET"),
            attributes: [
                NSAttributedStringKey.foregroundColor: UIColor.white,
                NSAttributedStringKey.font: rightFont,
            ]
        )
        title.append(rightText)
        buttonInvite.setAttributedTitle(title, for: UIControlState())
        
    }
}
