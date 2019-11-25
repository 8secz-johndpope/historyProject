//
//  HomeHeaderView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 3/27/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

class HomeHeaderView: UICollectionReusableView {
    
    static let ViewHeight: CGFloat = 71
    var leftView = UIView()
    var rightView = UIView()
    var label = UILabel()
    static let MarginTop = CGFloat(6)
    var padding = CGFloat(16)
    let PaddingLeft = CGFloat(16)
    let PaddingRight = CGFloat(16)
    private var lineSize: CGSize?
    
    static let LabelHeight:CGFloat = 15.0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        
        leftView.backgroundColor = UIColor.secondary1()
        rightView.backgroundColor = UIColor.secondary1()
        
        self.addSubview(leftView)
        self.addSubview(rightView)
        
        label.text = String.localize("LB_CA_HIGHLIGHT_PROMOTION")
        if let fontBold = UIFont(name: Constants.Font.Bold, size: 16) {
            label.font = fontBold
        } else {
            label.formatSizeBold(16)
        }
        label.textColor = UIColor.black
        self.addSubview(label)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let originY = CGFloat(28)
        var width = StringHelper.getTextWidth(label.text ?? "", height: HomeHeaderView.LabelHeight, font: label.font)
        label.frame = CGRect(x: (self.bounds.sizeWidth - width) / 2,  y: originY, width: width, height: HomeHeaderView.LabelHeight)
        
        let height = CGFloat(0.5)
        width = (self.bounds.sizeWidth - width - 2 * padding) / 2
        
        if let lineSize = self.lineSize {
            leftView.frame = CGRect(x: label.frame.minX - padding - lineSize.width, y: label.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
            rightView.frame = CGRect(x: label.frame.maxX + padding, y: label.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
        }
        else{
            leftView.frame = CGRect(x: PaddingLeft, y: label.frame.midY - height / 2, width: width - PaddingLeft, height: height)
            rightView.frame = CGRect(x: label.frame.maxX + padding , y: label.frame.midY - height / 2, width: width - PaddingRight, height: height)
        }
    }

    func formatStyle(_ textFont: UIFont? = nil, textColor: UIColor, lineColor: UIColor, lineSize: CGSize, space:CGFloat? = nil){
        if let textFont = textFont{
            label.font = textFont
        }
        else if let fontBold = UIFont(name: Constants.Font.Bold, size: 16) {
            label.font = fontBold
        } else {
            label.formatSizeBold(16)
        }
        
        label.textColor = textColor
        leftView.backgroundColor = lineColor
        rightView.backgroundColor = lineColor
        
        let originY = CGFloat(28)
        let textWidth = StringHelper.getTextWidth(label.text ?? "", height: HomeHeaderView.LabelHeight, font: label.font)
        label.frame = CGRect(x: (bounds.sizeWidth - textWidth) / 2,  y: originY, width: textWidth, height: HomeHeaderView.LabelHeight)
        
        self.lineSize = lineSize
        self.padding = space ?? self.padding
        leftView.frame = CGRect(x: label.frame.minX - self.padding - lineSize.width, y: label.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
        rightView.frame = CGRect(x: label.frame.maxX + self.padding, y: label.frame.midY - lineSize.height / 2, width: lineSize.width, height: lineSize.height)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
