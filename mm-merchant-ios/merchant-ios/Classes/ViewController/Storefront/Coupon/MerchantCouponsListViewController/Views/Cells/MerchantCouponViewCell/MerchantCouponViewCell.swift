//
//  MerchantCouponViewCell.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/22/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation
import PromiseKit

class MerchantCouponViewCell: BaseCouponViewCell {
    
    var isClaimedCoupon = false

    override var data: Coupon? {
        didSet {
            if let coupon = data {

                fillData(coupon)
                expand(coupon.isExpanded)
                
                lblCouponNote.font = UIFont.fontLightWithSize(14)
                lblCouponNote.text = coupon.couponRemark
                
                let height = 36 + StringHelper.heightForText(coupon.couponRemark, width: frame.width - 60, font: UIFont.fontLightWithSize(14))
                couponNoteContainerHeight.constant = height
                
                setButtonClaim(isClaimedCoupon)
                setCouponState(.none)
                
                if !isActiveCoupon {
                    self.iconMerchant.setImageColor(color: .gray)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        button.redRoundRectButton()
        button.setTitleColor(UIColor.red, for: UIControlState())
    }
    
    func setButtonClaim(_ claimed: Bool) {
        button.isHidden = !isActiveCoupon
        button.setTitle( isClaimedCoupon ? String.localize("去使用") : String.localize("LB_CA_INCENTIVE_REF_REFERRER_CLAIM") , for: UIControlState())
        button.setTitleColor( isClaimedCoupon ? .red : .white, for: .normal)
        button.backgroundColor = isClaimedCoupon ? .white : .red
    }

    @IBAction func toggleExpandCollapse(_ sender: UIButton) {
        if let coupon = data {

            coupon.isExpanded = !coupon.isExpanded
            expand(coupon.isExpanded)

            toggleExpandCollapseHandler?()
        }
    }
}
