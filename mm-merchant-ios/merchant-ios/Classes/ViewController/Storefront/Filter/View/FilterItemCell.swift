//
//  FilterItemCell.swift
//  merchant-ios
//
//  Created by Choi Fung Fung on 2/3/2016.
//  Copyright © 2016年 WWE & CO. All rights reserved.
//

import Foundation
import UIKit

class FilterItemCell: UICollectionViewCell {
    var textLabel = UILabel()
    var borderView = UIView()
    var arrowView = UIImageView()
    var selectLabel = UILabel()
    let arrowIcon = UIImage()
    
    
    private final let MarginCenter : CGFloat = 21
    private final let LogoMarginRight : CGFloat = 10
    private final let LabelMarginTop : CGFloat = 15
    private final let LabelMarginRight : CGFloat = 30
    private final let LogoWidth : CGFloat = 44
    private final let LabelLowerMarginTop : CGFloat = 33
    private final let MarginCell : CGFloat = 16
    private final let MarginLeft : CGFloat = 40
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        textLabel.formatSize(14)
        addSubview(textLabel)
        borderView.backgroundColor = UIColor.secondary1()
        addSubview(borderView)
        addSubview(arrowView)
        selectLabel.textColor = UIColor.secondary2()
        selectLabel.font = UIFont(name: selectLabel.font.fontName, size: 12)
        selectLabel.lineBreakMode = .byWordWrapping
        selectLabel.numberOfLines = 0
        selectLabel.textAlignment = .right
        addSubview(selectLabel)
        arrowView.image = UIImage(named: "filter_right_arrow")
        textLabel.font = UIFont(name:"HelveticaNeue-Bold", size: 14.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        textLabel.frame = CGRect(x: bounds.minX + MarginCell, y: bounds.midY - MarginCenter, width: bounds.size.width - 50, height: 42)
        borderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        arrowView.frame = CGRect(x: bounds.maxX - MarginCell - arrowView.image!.size.width , y: bounds.midY - arrowView.image!.size.height / 2 , width: arrowView.image!.size.width, height: arrowView.image!.size.height)
        selectLabel.frame = CGRect(x: bounds.maxX - 230 , y: bounds.minY, width: arrowView.frame.minX - (bounds.maxX - 230) - 15 , height: bounds.height)
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showArrowView(_ isShow: Bool){
        arrowView.isHidden = !isShow
    }
}
