//
//  ButtonCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class ButtonCell : UICollectionViewCell {
    var button = UIButton()
    var itemLabel = UILabel()
    var borderView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        button.setTitleColor( UIColor.primary1(), for: UIControlState())
        button.formatPrimary()
        addSubview(button)
        itemLabel.formatSize(14)
        addSubview(itemLabel)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)

    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var height = bounds.height - 20
        
        if height > 40 {
            height = 40
        }
        
        button.frame = CGRect(x: bounds.width / 3 * 2 + 10, y: bounds.minY + 10, width: bounds.width / 3 - 20, height: height)
        itemLabel.frame = CGRect(x: bounds.minX + 15, y: bounds.minY, width: bounds.width / 2 , height: height + 20)

        borderView.frame = CGRect(x: bounds.minX, y:bounds.minY, width: bounds.width, height: 1)
    }

}
