//
//  SubCatCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 27/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class BrandSubCatCell : UICollectionViewCell {
    var label = UILabel()
    var imageView = UIImageView()
    private final let RightArrowWidth : CGFloat = 7.0
    private final let RightArrowHeight : CGFloat = 15.0
    private final let MarginLeft : CGFloat = 10.0
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "icon_arrow")
        addSubview(imageView)
        label.formatSmall()
        label.textAlignment = .center
        label.backgroundColor = UIColor.white
        label.textColor = UIColor.secondary2()
        contentView.addSubview(label)
       
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x:  bounds.maxX - (RightArrowWidth + MarginLeft) , y: bounds.midY - RightArrowHeight/2 , width: RightArrowWidth , height: RightArrowHeight)
        label.frame = CGRect(x: MarginLeft , y: 0 ,width: bounds.maxX - (RightArrowWidth + MarginLeft * 3), height: bounds.maxY)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
