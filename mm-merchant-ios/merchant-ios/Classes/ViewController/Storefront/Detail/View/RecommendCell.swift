//
//  RecommendCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 2/12/2015.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation
class RecommendedCell : UICollectionViewCell{
    var textLabel = UILabel()
    var numberLabel = UILabel()
    private final let LabelHeight = CGFloat(20.0)
    private final let MarginBottom = CGFloat(15.0)
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        textLabel.formatSmall()
        textLabel.text = String.localize("LB_CA_NUM_PPL_RCMD_ITEM")
        addSubview(textLabel)
        numberLabel.formatSmall()
        numberLabel.textAlignment = .right
        addSubview(numberLabel)
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = CGRect(x: bounds.center.x - 50, y: bounds.maxY - (LabelHeight + MarginBottom) , width: 120, height: LabelHeight)
        numberLabel.frame = CGRect(x: bounds.center.x - 100, y: bounds.maxY - (LabelHeight + MarginBottom) , width: 50, height: LabelHeight)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
