//
//  HashTagOfficalCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class HashTagOfficalCell: UICollectionViewCell {
    
    static var CellIdentifier = "HashTagOfficalCell"
    static var ViewHeight = CGFloat(55)
    var label = UILabel()
    var iconImageView = UIImageView()
    var countLabel = UILabel()
    var lineView = UIView()
    var data: HashTag? {
        didSet {
            if let hashtag = data {
                label.text = hashtag.getHashTag()
                countLabel.text = hashtag.placeHolder
                
                if hashtag.badgeCode == "HOT" {
                    iconImageView.image = UIImage(named: "icon_hot")
                }else if hashtag.badgeCode == "NEW" {
                    iconImageView.image = UIImage(named: "icon_new")
                }
                iconImageView.isHidden = hashtag.badgeCode.length == 0
            }
            self.layoutSubviews()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        label.applyFontSize(14, isBold: false)
        label.textColor = UIColor.secondary2()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        self.contentView.addSubview(label)
        
        countLabel.applyFontSize(14, isBold: false)
        countLabel.textColor = UIColor.secondary2()
        self.contentView.addSubview(countLabel)
        
        iconImageView.image = UIImage(named: "icon_hot")
        self.contentView.addSubview(iconImageView)
        
        lineView.backgroundColor = UIColor.primary2()
        self.contentView.addSubview(lineView)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = iconImageView.image?.size ?? CGSize(width: 16, height: 16)
        let labelHeight = self.bounds.sizeHeight
        var width = StringHelper.getTextWidth(label.text ?? "", height: labelHeight, font: label.font)
        let maxWidth = self.frame.size.width - Margin.left - size.width - Margin.left / 2 - Margin.left
        if width > maxWidth {
            width = maxWidth
        }
        label.frame = CGRect(x: Margin.left, y: 0, width: width, height: labelHeight)
        
        width = StringHelper.getTextWidth(countLabel.text ?? "", height: labelHeight, font: countLabel.font)
        countLabel.frame = CGRect(x: self.frame.sizeWidth - Margin.left - width, y: 0, width: width, height: labelHeight)
        
        
        
        iconImageView.frame = CGRect(x: label.frame.maxX + Margin.left / 2, y: (self.bounds.sizeHeight - size.height)/2, width: size.width, height: size.height)
        
        lineView.frame = CGRect(x: Margin.left, y: self.bounds.sizeHeight - 1, width: self.bounds.sizeWidth - Margin.left, height: 1)
    }
}
