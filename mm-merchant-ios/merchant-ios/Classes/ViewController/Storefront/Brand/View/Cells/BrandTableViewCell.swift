//
//  BrandTableViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 7/18/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class BrandTableViewCell: UITableViewCell {

    @IBOutlet weak var brandImageView: UIImageView!
    @IBOutlet weak var brandName: UILabel!
    @IBOutlet weak var viewSeparator: UIView!
    static let CellIdentifier = "CellIdentifier"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        brandName.applyFontSize(15, isBold: true)
        
        viewSeparator.backgroundColor = UIColor.secondary1()
    }


    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    

}
