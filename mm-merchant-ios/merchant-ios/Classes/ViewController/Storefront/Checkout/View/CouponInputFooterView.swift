//
//  CouponInputFooterView.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CouponInputFooterView: UICollectionReusableView {
    
    private final let TopMargin: CGFloat = 12
    private final let MarginLeftRight: CGFloat = 15
    private final let AddButtonWidth: CGFloat = 80
    private final let Spacing: CGFloat = 10
    private final let AddButtonHeight: CGFloat = 40
    private final let CheckMarkHeight: CGFloat = 10
    private final let CheckMarkWidth: CGFloat = 16
    
    var checkboxButton = UIButton(type: .custom)
    var couponInputView = UIView()
    var textFieldCouponInput = UITextField()
    var couponNameLabel = UILabel()
    var priceLabel = UILabel()
    var separatorView = UIView()
    var addButton = UIButton()
    
    private var coupon: Coupon?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        checkboxButton.config(
            normalImage: UIImage(named: "icon_checkbox_unchecked"),
            selectedImage: UIImage(named: "icon_checkbox_checked")
        )
        checkboxButton.sizeToFit()
        checkboxButton.isUserInteractionEnabled = false
        self.addSubview(checkboxButton)
        
        couponInputView.backgroundColor = UIColor.white
        couponInputView.layer.borderColor = UIColor.secondary1().cgColor
        couponInputView.layer.borderWidth = Constants.ActionButton.BorderWidth
        couponInputView.layer.cornerRadius = Constants.ActionButton.Radius
        self.addSubview(couponInputView)
        
        textFieldCouponInput.font = UIFont(name: Constants.Font.Normal, size: Constants.Font.Size)
        textFieldCouponInput.textColor = UIColor.secondary2()
        textFieldCouponInput.returnKeyType = .done
        self.textFieldCouponInput.clearButtonMode = .whileEditing
        self.couponInputView.addSubview(self.textFieldCouponInput)
        
        addButton.formatSecondary()
        addButton.setTitle(String.localize("LB_CA_CHECKOUT_COUPON_APPLY"), for: UIControlState())
        self.addSubview(addButton)
        
        priceLabel.formatSize(15)
        priceLabel.textColor = UIColor.primary1()
        self.addSubview(priceLabel)
        
        couponNameLabel.formatSize(15)
        self.addSubview(couponNameLabel)
        
        separatorView.backgroundColor = UIColor.backgroundGray()
        self.addSubview(self.separatorView)
        self.separatorView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        checkboxButton.frame = CGRect(x: MarginLeftRight, y: (AddButtonHeight - checkboxButton.height) / 2 + TopMargin, width: checkboxButton.width, height: checkboxButton.height)
        
        couponInputView.frame = CGRect(x: checkboxButton.frame.maxX + MarginLeftRight, y: TopMargin, width: frame.width - (checkboxButton.frame.maxX + MarginLeftRight * 2 + AddButtonWidth + Spacing), height: AddButtonHeight)
        
        textFieldCouponInput.frame = CGRect(x: Spacing, y: 0, width: couponInputView.width - Spacing, height: couponInputView.height)
        
        addButton.frame = CGRect(x: couponInputView.frame.maxX + Spacing, y: TopMargin, width: AddButtonWidth, height: AddButtonHeight)
        
        setFrameForBottomViews()
        
        separatorView.frame = CGRect(x: MarginLeftRight, y: frame.height - 1, width: frame.width - MarginLeftRight * 2, height: 1)
    }
    
    func setFrameForBottomViews() {
        priceLabel.sizeToFit()
        priceLabel.frame = CGRect(x: checkboxButton.frame.maxX + MarginLeftRight, y: AddButtonHeight , width: priceLabel.frame.width, height: frame.height - AddButtonHeight)
        
        couponNameLabel.frame = CGRect(x: priceLabel.frame.maxX + Spacing , y: AddButtonHeight, width: frame.width - (priceLabel.frame.maxX + MarginLeftRight + Spacing), height: frame.height - AddButtonHeight)
    }
    
    func setData(_ coupon: Coupon? = nil, isShowMMCoupon: Bool = false) {
        self.coupon = coupon
        
        if let myCoupon = coupon {
            self.couponNameLabel.text = myCoupon.couponName
            
            let price = coupon?.couponAmount
            self.priceLabel.text = price?.formatPrice()
            
            checkboxButton.config(
                normalImage: UIImage(named: "icon_checkbox_unchecked"),
                selectedImage: UIImage(named: "icon_checkbox_checked")
            )
            self.checkboxButton.isSelected = myCoupon.isSelected
            
            textFieldCouponInput.text = myCoupon.couponReference
            
            self.couponNameLabel.isHidden = (!myCoupon.isAvailable || !myCoupon.isRedeemable)
            
            self.priceLabel.isHidden = (!myCoupon.isAvailable || !myCoupon.isRedeemable)
        } else {
            self.couponNameLabel.text = ""
            
            self.priceLabel.text = ""
            
            checkboxButton.config(
                normalImage: UIImage(named: "icon_checkbox_disable"),
                selectedImage: UIImage(named: "icon_checkbox_disable")
            )
            
            self.checkboxButton.isSelected = false
            
            textFieldCouponInput.text = ""
        }
        
        textFieldCouponInput.placeholder = isShowMMCoupon ? String.localize("LB_CA_CHECKOUT_MYMM_COUPON_CODE") : String.localize("LB_CA_CHECKOUT_MERC_COUPON_CODE")
        
        setFrameForBottomViews()
    }
    
    func resetCouponNameAndPrice(){
        couponNameLabel.text = ""
        
        priceLabel.text = ""
    }
    
    func enableCheckBox(_ isEnable: Bool){
        checkboxButton.config(
            normalImage: UIImage(named: isEnable ? "icon_checkbox_unchecked" : "icon_checkbox_disable"),
            selectedImage: UIImage(named: isEnable ? "icon_checkbox_checked" : "icon_checkbox_disable")
        )
    }

}
