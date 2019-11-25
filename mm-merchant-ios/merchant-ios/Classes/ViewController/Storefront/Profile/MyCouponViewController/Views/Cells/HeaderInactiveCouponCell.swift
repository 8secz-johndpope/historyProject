//
//  HeaderInactiveCouponCell.swift
//  merchant-ios
//
//  Created by HungPM on 3/16/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class HeaderInactiveCouponCell: UITableViewCell {
    
    @IBOutlet weak var lblTitle: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        lblTitle.text = String.localize("LB_CA_PROFILE_MY_COUPON_EXPIRED_LIST")
        lblTitle.textColor = UIColor.secondary3()
    }
}
