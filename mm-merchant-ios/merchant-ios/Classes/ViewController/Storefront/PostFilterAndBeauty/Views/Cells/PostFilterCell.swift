//
//  PostFilterCell.swift
//  merchant-ios
//
//  Created by HungPM on 9/12/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit


class PostFilterCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var model: MMFilter? {
        didSet{
            if let model = model {
                imageView.image = UIImage(named: model.normalImageName)
                label.text = model.title
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        label.font = UIFont.boldFontWithSize(10)
        label.textColor = UIColor.gray
    }

    func setFilterSelected(_ selected: Bool) {
        if selected {
            imageView.layer.borderWidth = 1.5
            label.textColor = UIColor.secondary2()
        } else {
            imageView.layer.borderWidth = 0
            label.textColor = UIColor.gray
        }
    }
}
