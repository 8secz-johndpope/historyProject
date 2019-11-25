//
//  PostBeautyCell.swift
//  merchant-ios
//
//  Created by HungPM on 9/12/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class PostBeautyCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var model: BeautyOption? {
        didSet{
            if let model = model {
                
                imageView.contentMode = .scaleAspectFit
                label.text = model.title
                
                if model.selected == true {
                    label.textColor = UIColor.black
                    imageView.image = UIImage(named: model.selectImageName)
                    imageView.alpha = 1
                } else {
                    label.textColor = UIColor.secondary3()
                    imageView.image = UIImage(named: model.normalImageName)
                    imageView.alpha = 0.5
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
