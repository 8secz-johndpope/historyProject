//
//  MerchantCouponInputCell.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/14/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MerchantCouponInputCell: CouponSelectionCell, UITextFieldDelegate {
    @IBOutlet weak var tfCoupon: UITextField!
    @IBOutlet weak var btnCheckCoupon: UIButton!
    @IBOutlet weak var lblCoupon: UILabel!
    
    var checkBoxTapHandler: ((_ cell: MerchantCouponInputCell) -> ())?
    var checkCouponHandler: ((_ couponCode: String?) -> ())?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        btnCheckBox.config(normalImage: UIImage(named: "icon_checkbox_unchecked"), selectedImage: UIImage(named: "icon_checkbox_checked"))
        btnCheckCoupon.setTitle(String.localize("LB_CA_CHECKOUT_COUPON_CODE_CHECK"), for: UIControlState())
        btnCheckBox.isUserInteractionEnabled = false

        btnCheckCoupon.setTitleColor(UIColor.secondary2(), for: UIControlState())
        
        tfCoupon.layer.borderColor = UIColor.lightGray.cgColor
        tfCoupon.layer.borderWidth = 1
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: 6, height: tfCoupon.frame.height))
        leftView.backgroundColor = tfCoupon.backgroundColor
        tfCoupon.leftView = leftView
        tfCoupon.leftViewMode = .always
        tfCoupon.delegate = self
        
        btnCheckCoupon.layer.borderColor = UIColor.lightGray.cgColor
        btnCheckCoupon.layer.borderWidth = Constants.Button.BorderWidth
        btnCheckCoupon.layer.cornerRadius = Constants.Button.Radius
        lblCoupon.isHidden = true
    }
    
    @IBAction func buttonCheckBoxTapped(_ sender: UIButton) {
        if sender.isSelected {
            return
        }
        
        btnCheckBox.isSelected = true
        checkBoxTapHandler?(self)
    }
    
    @IBAction func buttonCheckTapped(_ sender: Any) {
        tfCoupon.resignFirstResponder()
        
        checkCouponHandler?(tfCoupon.text)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        checkCouponHandler?(tfCoupon.text)
        return true
    }
    
    func setCouponInfo(_ coupon: Coupon?) {
        if let coupon = coupon, let amount = coupon.couponAmount.formatPrice() {
            let couponString = NSMutableAttributedString(string: amount, attributes: [NSAttributedStringKey.foregroundColor : UIColor.red])
            let nametString = NSAttributedString(string: " " + coupon.couponName, attributes: [NSAttributedStringKey.foregroundColor : UIColor.secondary2()])
            couponString.append(nametString)
            couponString.addAttributes([NSAttributedStringKey.font : UIFont.fontLightWithSize(14)], range: NSRange(location: 0, length: couponString.length))
            lblCoupon.attributedText = couponString
            
            lblCoupon.isHidden = false
            
            tfCoupon.text = coupon.couponReference
        }
        else {
            lblCoupon.attributedText = nil
            lblCoupon.isHidden = true
        }
    }
}
