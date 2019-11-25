//
//  PlaceHolderCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 8/17/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class PlaceHolderCell: UICollectionViewCell {

    static let PlaceHolderCellIdentifier = "PlaceHolderCellIdentifier"
    private final let LabelHeight: CGFloat = 40
    private var ImageViewHeight:CGFloat = 66
    private var ImageViewWidth:CGFloat = 66
    
    var imageView = UIImageView()
    var descriptionLabel =  UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.image = UIImage(named: "placeholder_icon")
        addSubview(imageView)
        descriptionLabel.formatSmall()
        descriptionLabel.text = String.localize("LB_CA_NO_POST")
        descriptionLabel.textAlignment = .center
        addSubview(descriptionLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let imageViewHeight = imageView.image?.size.height ?? ImageViewHeight
        let imageViewWidth = imageView.image?.size.width ?? ImageViewWidth
        imageView.frame = CGRect(x: (self.width - imageViewWidth) / 2, y: (self.height - (imageViewHeight + LabelHeight)) / 2, width: imageViewWidth,  height: imageViewHeight)
        descriptionLabel.frame = CGRect(x: 0, y: imageView.frame.maxY, width: self.width, height: LabelHeight)
    }
}
