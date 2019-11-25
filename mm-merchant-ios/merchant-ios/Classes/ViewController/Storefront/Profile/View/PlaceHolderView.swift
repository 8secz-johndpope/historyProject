//
//  PlaceHolderView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 4/18/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class PlaceHolderView: UIView {

    static  let LabelHeight: CGFloat = 40
    static var ImageViewHeight:CGFloat = 66
    static var ImageViewWidth:CGFloat = 66
    
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
        let imageViewHeight = imageView.image?.size.height ?? PlaceHolderView.ImageViewHeight
        let imageViewWidth = imageView.image?.size.width ?? PlaceHolderView.ImageViewWidth
        imageView.frame = CGRect(x: (self.width - imageViewWidth) / 2, y: (self.height - (imageViewHeight + PlaceHolderView.LabelHeight)) / 2, width: imageViewWidth,  height: imageViewHeight)
        descriptionLabel.frame = CGRect(x: 0, y: imageView.frame.maxY, width: self.width, height: PlaceHolderView.LabelHeight)
    }
    
}
