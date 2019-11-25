//
//  IMSocialCell.swift
//  merchant-ios
//
//  Created by HungPM on 9/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class IMSocialCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblBadge: UILabel!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var separator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        imageView.round()
        
        lblBadge.round()
        lblBadge.backgroundColor = .red
        lblBadge.textColor = .white
        
        lblTitle.font = UIFont.usernameFont()
        lblTitle.textColor = .black
        lblTitle.lineBreakMode = .byTruncatingTail
        lblTitle.numberOfLines = 1
        
        separator.backgroundColor = UIColor.secondary1()
    }

}
