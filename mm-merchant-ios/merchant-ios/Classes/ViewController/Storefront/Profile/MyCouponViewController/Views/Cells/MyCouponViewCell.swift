//
//  MyCouponViewCell.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MyCouponViewCell: BaseCouponViewCell {

    var shouldShowButton = true

    override var data: Coupon? {
        didSet {
            if let coupon = data {
                fillData(coupon, shouldShowMerchantName: coupon.merchantId != Constants.MMMerchantId ? true : false)
                expand(coupon.isExpanded)
                
                lblCouponNote.font = UIFont.fontLightWithSize(14)
                lblCouponNote.text = coupon.couponRemark
                
                let height = 40 + StringHelper.heightForText(coupon.couponRemark, width: frame.width - 60, font: UIFont.fontLightWithSize(14))
                couponNoteContainerHeight.constant = height

                if !isActiveCoupon {
                    setCouponState(CouponState.inactive)
                }
                else {
                    if coupon.isNew() {
                        setCouponState(.new)
                    }
                    else {
                        setCouponState(.none)
                    }
                }
                
                if shouldShowButton {
                    button.isHidden = false
                    trailingConstraint.constant = CGFloat(84)
                }
                else {
                    button.isHidden = true
                    trailingConstraint.constant = CGFloat(6)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        button.redRoundRectButton()
        button.setTitle(String.localize("LB_CA_PROFILE_MY_COUPON_SHOP"), for: UIControlState())
        button.setTitle(String.localize("LB_CA_PROFILE_MY_COUPON_SHOP"), for: .highlighted)
        button.setTitleColor(UIColor.red, for: UIControlState())
    }

    @IBAction func toggleExpandCollapse(_ sender: UIButton) {
        if let coupon = data {
            
            coupon.isExpanded = !coupon.isExpanded
            expand(coupon.isExpanded)
            
            toggleExpandCollapseHandler?()
        }
    }
}
