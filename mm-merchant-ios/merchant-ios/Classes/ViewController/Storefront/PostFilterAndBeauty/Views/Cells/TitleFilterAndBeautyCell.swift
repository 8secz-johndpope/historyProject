//
//  TitleFilterAndBeautyCell.swift
//  merchant-ios
//
//  Created by HungPM on 9/15/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit


class TitleFilterAndBeautyCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    
    var model: PostCreateData? {
        didSet{
            imageView.layer.borderWidth = (model?.isCurrentFilterTarget == true) ? 1 : 0
            imageView.image = model?.processedImage
        }
    }
    
    override func awakeFromNib() {
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 0
    }
    
}
