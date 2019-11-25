//
//  MerchantCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 5/8/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class MerchantCell: ImageMenuCell {
    static let CellIdentifier: String = "CellIdentifier"
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        if let font = UIFont(name: Constants.Font.Bold, size: 15) {
            upperLabel.font = font
        } else {
            upperLabel.formatSize(15)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
