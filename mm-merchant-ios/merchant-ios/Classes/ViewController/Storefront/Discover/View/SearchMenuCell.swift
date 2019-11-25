//
//  FilterCell.swift
//  merchant-ios
//
//  Created by Koon Kit Chan on 24/11/15.
//  Copyright © 2015 Koon Kit Chan. All rights reserved.
//

import Foundation

class SearchMenuCell : UICollectionViewCell{
    var textLabel = UILabel()
    var borderView = UIView()
    var selectLabel = UILabel()
    
    private final let MarginCenter : CGFloat = 21
    private final let LogoMarginRight : CGFloat = 10
    private final let LabelMarginTop : CGFloat = 15
    private final let LabelMarginRight : CGFloat = 30
    private final let LogoWidth : CGFloat = 44
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let MarginLeft : CGFloat = 10
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor(hexString: "#f5f5f5")
        layer.cornerRadius = 3
        layer.masksToBounds = true
        textLabel.textColor = UIColor.hashtagColor()
        textLabel.textAlignment = .center
        textLabel.font = UIFont.systemFont(ofSize: 12)
        addSubview(textLabel)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        selectLabel.textColor = UIColor.secondary2()
        selectLabel.font = UIFont(name: selectLabel.font.fontName, size: 12)
        selectLabel.lineBreakMode = .byWordWrapping
        selectLabel.numberOfLines = 0
        addSubview(selectLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = CGRect(x: bounds.minX + MarginLeft, y: bounds.minY , width: bounds.size.width - MarginLeft * 2, height: bounds.height)
        borderView.frame = CGRect(x: bounds.minX + MarginLeft, y: bounds.maxY - 1, width: bounds.size.width - MarginLeft * 2, height: 1)
        selectLabel.frame = CGRect(x: bounds.maxX - 230 , y: bounds.minY, width: 200 , height: bounds.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
