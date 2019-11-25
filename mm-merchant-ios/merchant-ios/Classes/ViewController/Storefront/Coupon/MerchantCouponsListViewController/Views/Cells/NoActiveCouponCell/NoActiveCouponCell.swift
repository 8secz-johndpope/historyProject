//
//  NoActiveCouponCell.swift
//  merchant-ios
//
//  Created by Phan Manh Hung on 2/3/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class NoActiveCouponCell: UITableViewCell {
    
    @IBOutlet weak var lblCouponEmpty: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        lblCouponEmpty.textColor = UIColor.secondary3()
    }
}
