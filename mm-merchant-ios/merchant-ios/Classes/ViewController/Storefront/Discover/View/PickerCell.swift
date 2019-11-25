//
//  PickerCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 7/1/2016.
//  Copyright © 2016 Koon Kit Chan. All rights reserved.
//

import Foundation

class PickerCell: UICollectionViewCell {
    
    static let CellIdentifier = "PickerCellID"
    
    var label = UILabel()
    var imageView = UIImageView()
    var borderView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        
        label.formatSmall()
        label.textAlignment = .left
        contentView.addSubview(label)
        
        addSubview(imageView)
        
        borderView.isHidden = true
        borderView.isUserInteractionEnabled = false
        borderView.layer.borderColor = UIColor.secondary1().cgColor
        borderView.layer.borderWidth = 1.0
        borderView.backgroundColor = UIColor.clear
        addSubview(borderView)
    }
    
    override func layoutSubviews() {
        label.frame = CGRect(x: bounds.minX + 15, y: bounds.minY, width: bounds.width - 64 , height: bounds.height)
        imageView.frame = CGRect(x: bounds.maxX - 50, y: bounds.midY - 6, width: 16, height: 12)
        borderView.frame = CGRect(x: bounds.minX - 1, y: bounds.minY, width: bounds.width + 2, height: bounds.maxY)//Use top and bottom border line only
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
