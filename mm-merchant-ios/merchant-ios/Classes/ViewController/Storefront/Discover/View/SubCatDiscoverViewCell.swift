//
//  SubCatDiscoverViewCell.swift
//  merchant-ios
//
//  Created by Tho NT Chan on 06/01/16.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class SubCatDiscoverViewCell : UICollectionViewCell {
    var label = UILabel()
    var imageView = UIImageView()
    var imageViewUnderLine = UIImageView()
    var countLabel = UILabel()
    
    var firstSeparateLine = UIView()
    var firstImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        backgroundColor = UIColor.white
        label.formatSmall()
        label.backgroundColor = UIColor.white
        countLabel.formatSize(11)
        
        firstSeparateLine.backgroundColor = UIColor.secondary1()
        firstSeparateLine.isHidden = true
        firstImageView.contentMode = .scaleAspectFill
        
        contentView.addSubview(label)
        addSubview(imageView)
        addSubview(imageViewUnderLine)
        addSubview(countLabel)
        addSubview(firstSeparateLine)
        addSubview(firstImageView)
        
        layoutSubviews()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var textWidth: CGFloat = 0
        
        if let text = label.text {
            textWidth = StringHelper.getTextWidth(text, height: 20, font: label.font)
        }
        
        var labelOffsetX = (frame.width - textWidth) / 2
        
        if imageView.image != nil {
            labelOffsetX = (frame.width - textWidth - 12) / 2
        }
        
        label.frame = CGRect(x: labelOffsetX, y: bounds.midY - 10, width: textWidth, height: 20)
        imageView.frame = CGRect(x: label.frame.maxX + 4, y: bounds.midY - 5, width: 6, height: 9)
        imageViewUnderLine.frame = CGRect(x: bounds.midX - 40, y: bounds.midY + 11, width: 80, height: 2)
        countLabel.frame = CGRect(x: label.frame.maxX, y: bounds.midY - 10, width: 20, height: 20)
        firstSeparateLine.frame = CGRect(x: 0, y: 15, width: 1, height: bounds.sizeHeight - 30)
        firstImageView.frame = CGRect(x: label.frame.originX - 16, y: bounds.midY - 7, width: 14, height: 14)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(_ text: String) {
        label.text = text
        layoutSubviews()
    }
    
}
