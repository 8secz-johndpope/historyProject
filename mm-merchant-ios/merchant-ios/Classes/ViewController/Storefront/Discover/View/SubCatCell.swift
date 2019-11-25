//
//  SubCatCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 27/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class SubCatCell : UICollectionViewCell {
    var label = UILabel()
    var imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
       
        imageView.clipsToBounds = true
        addSubview(imageView)
       
        label.formatSmall()
        label.textAlignment = .center
        label.backgroundColor = UIColor.clear
        contentView.addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = CGRect(x: 0, y: bounds.height - 8, width: bounds.width, height: 1)
        label.frame = bounds
        
//        if let text = label.text, text != "" {
//            let textWidth = StringHelper.getTextWidth(text, height: bounds.height, font: label.font)
//            let textHeight = StringHelper.heightForText(text, width: textWidth, font: label.font)
//        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
