//
//  BrandListCell.swift
//  merchant-ios
//
//  Created by HungPM on 5/23/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import Foundation

class BrandListCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var brandName: UILabel!
    @IBOutlet weak var viewSeparator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        brandName.applyFontSize(15, isBold: true)
        
        viewSeparator.backgroundColor = UIColor.secondary1()
    }
}
