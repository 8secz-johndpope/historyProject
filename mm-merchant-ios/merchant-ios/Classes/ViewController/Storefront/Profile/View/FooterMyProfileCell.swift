//
//  FooterMyProfileCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 30/9/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class FooterMyProfileCell : UICollectionReusableView{
    
    static let FooterMyProfileCellHeight:CGFloat = 145.0
    
    private let containerView = UIView()
    
    private let imageView = UIImageView()
    private let imageViewSize = CGSize(width: 50.0, height: 50.0)
    
    private let labelPlaceholder = UILabel()
    private let labelPaddingTop:CGFloat = 10.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
        
        containerView.backgroundColor = UIColor.clear
        addSubview(containerView)
        
        imageView.image = UIImage.init(named: "endPost_icon")
        containerView.addSubview(imageView)
        
        labelPlaceholder.formatSize(14)
        labelPlaceholder.textColor = UIColor.secondary3()
        labelPlaceholder.textAlignment = .center
        labelPlaceholder.text = String.localize("LB_NEWSFEED_BOTTOM")
        containerView.addSubview(labelPlaceholder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView.frame = CGRect(x: (frame.sizeWidth - imageViewSize.width)/2, y: 0, width: imageViewSize.width, height: imageViewSize.height)
        let textSize = labelPlaceholder.intrinsicContentSize
        labelPlaceholder.frame = CGRect(x: (frame.sizeWidth - textSize.width)/2, y: imageView.frame.maxY + labelPaddingTop, width: textSize.width, height: textSize.height)
        
        containerView.frame = CGRect(x: 0, y: (frame.sizeHeight - labelPlaceholder.frame.maxY)/2, width: frame.sizeWidth, height: labelPlaceholder.frame.maxY)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
