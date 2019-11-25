//
//  MerchantCouponDeselectCell.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/14/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MerchantCouponDeselectCell: CouponSelectionCell {
    @IBOutlet weak var label: UILabel!

    var checkBoxTapHandler: ((_ cell: MerchantCouponDeselectCell) -> ())?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        label.textColor = UIColor.secondary2()
        label.text = String.localize("LB_CA_CHECKOUT_COUPON_NOT_USE")
        
        btnCheckBox.config(normalImage: UIImage(named: "icon_checkbox_unchecked"), selectedImage: UIImage(named: "icon_checkbox_checked"))
    }
    
    @IBAction func buttonCheckBoxTapped(_ sender: UIButton) {
        if sender.isSelected {
            return
        }
        
        btnCheckBox.isSelected = true
        checkBoxTapHandler?(self)
    }
}
