//
//  TitleCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class TitleCell : UICollectionViewCell {
    var textLabel = UILabel()
    var valueLabel = UILabel()
    var borderView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        textLabel.formatSize(14)
        textLabel.font = UIFont.boldSystemFont(ofSize: 14)
        addSubview(textLabel)
        addSubview(valueLabel)
        addSubview(borderView)
        borderView.backgroundColor = UIColor.secondary1()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = CGRect(x: bounds.minX + 16, y: bounds.minY, width: bounds.width / 2 , height: bounds.height)
        valueLabel.frame = CGRect(x: bounds.maxX - 50, y: bounds.minY, width: 50 , height: bounds.height)
        borderView.frame = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.width, height: 1)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
