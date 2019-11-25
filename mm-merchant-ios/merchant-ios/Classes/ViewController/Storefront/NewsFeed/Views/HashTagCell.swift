//
//  HashTagCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/6/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class HashTagCell: UICollectionViewCell {
    
    enum HashTagType {
        case `default`
        case roundedBorder
    }
    
    var label = UILabel()
    var bgView = UIView()
    var type: HashTagType = .default
    
    static var CellIdentifier = "HashTagCell"
    static let FontSize = Int(13)
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bgView.backgroundColor = UIColor.filterBackground()
        bgView.layer.cornerRadius = 2
        self.contentView.addSubview(bgView)
        
        label.textColor = UIColor.secondary2()
        label.font = UIFont.fontWithSize(HashTagCell.FontSize, isBold: false)
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        self.contentView.addSubview(label)
        
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        bgView.frame = self.bounds
        label.frame = CGRect(x: Margin.left / 2, y: 0, width: self.frame.sizeWidth - Margin.left, height: self.frame.sizeHeight)
        
        if type == .roundedBorder {
            bgView.layer.borderColor = UIColor.filterBackground().cgColor
            bgView.layer.borderWidth = 1.0
            bgView.backgroundColor = UIColor.clear
            bgView.layer.cornerRadius = bgView.frame.sizeHeight/2
        }
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
