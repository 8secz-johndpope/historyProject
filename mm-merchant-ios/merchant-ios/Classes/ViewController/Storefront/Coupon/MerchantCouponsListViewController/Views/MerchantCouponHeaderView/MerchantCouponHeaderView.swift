//
//  MerchantCouponHeaderView.swift
//  merchant-ios
//
//  Created by Alan YU on 3/2/2017.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class MerchantCouponHeaderView: UITableViewCell {
    
    @IBOutlet weak var merchantIconView: UIImageView!
    @IBOutlet weak var merchantTitleLabel: UILabel!
    @IBOutlet weak var trailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightView: UIView!
    @IBOutlet weak var lblCouponShop: UILabel!
    @IBOutlet weak var topSeparator: UIView!
    @IBOutlet weak var viewContainer: UIView!
    
    var data: Any? {
        didSet {
            if let merchant = data as? CartMerchant {
                if merchant.merchantId == Constants.MMMerchantId {
                    merchantIconView.image = Merchant().MMImageIcon
                }
                else {
                    merchantIconView.mm_setImageWithURL(
                        ImageURLFactory.URLSize1000(merchant.merchantImage, category: .merchant),
                        placeholderImage: UIImage(named: "holder"),
                        contentMode: .scaleAspectFit
                    )
                }
                merchantTitleLabel.text = merchant.merchantName
            }
            else if let merchant = data as? Merchant {
                if merchant.merchantId == Constants.MMMerchantId {
                    merchantIconView.image = Merchant().MMImageIcon
                }
                else {
                    merchantIconView.mm_setImageWithURL(
                        ImageURLFactory.URLSize1000(merchant.headerLogoImage, category: .merchant),
                        placeholderImage: UIImage(named: "holder"),
                        contentMode: .scaleAspectFit
                    )
                }
                merchantTitleLabel.text = merchant.merchantName
            }
            else {
                merchantIconView.image = nil
                merchantTitleLabel.text = nil
            }
            
            if rightView.isHidden {
                trailingConstraint.constant = 0
            }
            else {
                trailingConstraint.constant = rightView.bounds.width
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblCouponShop.text = String.localize("LB_CA_PROFILE_MY_COUPON_SHOP")
    }
}
