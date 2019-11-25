//
//  CouponInputView.swift
//  merchant-ios
//
//  Created by LongTa on 6/16/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CouponInputView: UIView {

    var labelMerchant = UILabel()
    var imageViewCheck = UIImageView()
    var viewTextfieldContainer = UIView()
    var buttonClear = UIButton()
    var textFieldCouponInput = UITextField()
    var viewBottom = UIView()
    var buttonConfirm = UIButton()
    
    private final let paddingLeftRight = CGFloat(20)
    private final let heightViewTextfieldContainer = CGFloat(50)
    private final let heightTextfield = CGFloat(30)
    private final let heightLabelMerchant = CGFloat(30)
    private final let heightClearButton = CGFloat(10)
    private final let heightBottomView = CGFloat(80)
    private final let heightConfirmButton = CGFloat(50)
    private final let heightSeperatorView = CGFloat(1)

    var isShowMMPopup = false
    var gotCouponResponseHandler:(() -> Void)?

    init() {
        super.init(frame: UIScreen.main.bounds)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupLayouts() {
        
        //merchant name label
        let frameLabelMerchant = CGRect(x: paddingLeftRight, y: paddingLeftRight, width: self.frame.size.width - 2*paddingLeftRight, height: heightLabelMerchant)
        labelMerchant.frame = frameLabelMerchant
        labelMerchant.font = UIFont(name: Constants.Font.Normal, size: Constants.Font.Size)
        labelMerchant.textColor = UIColor.secondary2()
        
        self.addSubview(labelMerchant)
        
        let frameViewTextfieldContainer = CGRect(x: paddingLeftRight, y: labelMerchant.frame.size.height + labelMerchant.frame.origin.y + paddingLeftRight/2, width: self.frame.size.width - 2*paddingLeftRight, height: heightViewTextfieldContainer)
        viewTextfieldContainer.frame = frameViewTextfieldContainer
        viewTextfieldContainer.layer.borderColor = UIColor.secondary1().cgColor
        viewTextfieldContainer.layer.borderWidth = heightSeperatorView
        self.addSubview(viewTextfieldContainer)
        
        //view check image
        let frameCheckImage = CGRect(x: paddingLeftRight/2, y: viewTextfieldContainer.frame.size.height/2 - heightClearButton/2, width: heightClearButton, height: heightClearButton)
        imageViewCheck.frame = frameCheckImage
        imageViewCheck.image = UIImage(named: "filter_icon_tick")
        imageViewCheck.contentMode = .scaleAspectFit
        viewTextfieldContainer.addSubview(imageViewCheck)
        
        // text field input coupon
        let frameTextField = CGRect(x: imageViewCheck.frame.origin.x + imageViewCheck.frame.size.width + paddingLeftRight/2,
                                        y: viewTextfieldContainer.frame.size.height/2 - heightTextfield/2,
                                        width: viewTextfieldContainer.frame.size.width - (paddingLeftRight + heightClearButton + imageViewCheck.frame.origin.x + imageViewCheck.frame.size.width),
                                        height: heightTextfield)
        textFieldCouponInput.frame = frameTextField
        textFieldCouponInput.font = UIFont(name: Constants.Font.Normal, size: Constants.Font.Size)
        textFieldCouponInput.textColor = UIColor.secondary2()
        textFieldCouponInput.placeholder = String.localize("LB_CA_CHECKOUT_MERC_COUPON_CODE")
        textFieldCouponInput.returnKeyType = UIReturnKeyType.done
        self.textFieldCouponInput.rightViewMode = .whileEditing
        
        buttonClear = UIButton(type: UIButtonType.system)
        buttonClear.setImage(UIImage(named: "btn_clear_textfield"), for: UIControlState())
        buttonClear.frame = CGRect(x: textFieldCouponInput.frame.width - heightClearButton, y: (textFieldCouponInput.frame.height - heightClearButton) / 2, width: heightClearButton, height: heightClearButton)
        buttonClear.tintColor = UIColor.gray

        self.textFieldCouponInput.rightView = buttonClear
        
        
        viewTextfieldContainer.addSubview(textFieldCouponInput)
        
        //bottom view
        let frameBottomView = CGRect(x: 0, y: self.frame.size.height - heightBottomView, width: self.frame.size.width, height: heightBottomView)
        viewBottom.frame = frameBottomView
        self.addSubview(viewBottom)
        
        // button confirm
        let frameButtonConfirm = CGRect(x: paddingLeftRight, y: viewBottom.frame.size.height/2 - heightConfirmButton/2, width: viewBottom.size.width - 2*paddingLeftRight, height: heightConfirmButton)
        buttonConfirm.frame = frameButtonConfirm
        buttonConfirm.titleLabel?.font = UIFont(name: Constants.Font.Normal, size: Constants.Font.Size)
        buttonConfirm.setTitleColor(UIColor.white, for: UIControlState())
        buttonConfirm.backgroundColor = UIColor.primary1()
        buttonConfirm.setTitle(String.localize("LB_CA_CONFIRM"), for: UIControlState())//dummy data
        buttonConfirm.layer.cornerRadius = 3.0

        viewBottom.addSubview(buttonConfirm)
        
        // seperator view
        let frameSeperatorView = CGRect(x: 0, y: 0, width: viewBottom.width, height: heightSeperatorView)
        let viewSeperatorView = UIView()
        viewSeperatorView.frame = frameSeperatorView
        viewSeperatorView.backgroundColor = UIColor.secondary1()
        viewBottom.addSubview(viewSeperatorView)
    }
    
    //MARK:
    
    func clearTextfield(){
        textFieldCouponInput.text = ""
    }
}
