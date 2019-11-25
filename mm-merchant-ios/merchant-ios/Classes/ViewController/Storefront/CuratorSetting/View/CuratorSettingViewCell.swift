//
//  CuratorSettingViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 5/31/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CuratorSettingViewCell: UICollectionViewCell {
    
    static let CellIdentifier = "CuratorSettingViewCell"
    
    private let heightLabel = CGFloat(22)
    private let heightTop = CGFloat(30)
    private let widthSquare = CGFloat(86)
    private let heightSquare = CGFloat(100)
    private let widthRect = CGFloat(235)
    private let heightRect = CGFloat(100)

    var topView: UIView!
    var labelCuratorCover : UILabel!
    var imageViewCoverSquare: UIImageView!
    var imageViewCoverRect: UIImageView!
    var lineView: UIView!
    
    var labelSquare = UILabel()
    var labelRect = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        topView = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: heightTop))
        topView.backgroundColor = UIColor.secondary6()
        addBottomBorderWithColor(UIColor.secondary1(), andWidth: 1)
        addSubview(topView)
        
        labelCuratorCover = UILabel(frame: CGRect(x: Margin.left * 2, y: (heightTop - heightLabel) / 2, width: bounds.width - Margin.left * 4, height: heightLabel))
        labelCuratorCover.formatSize(14)
        labelCuratorCover.text = String.localize("LB_CA_CURATOR_COVER")
        topView.addSubview(labelCuratorCover)
        
        lineView = UIView(frame: CGRect(x: 0, y: topView.frame.maxY - 1, width: bounds.width, height: 1))
        lineView.backgroundColor = UIColor.secondary1()
        topView.addSubview(lineView)
        
        imageViewCoverSquare = UIImageView(frame: CGRect(x: Margin.left * 2, y: topView.frame.maxY + Margin.top * 2, width: widthSquare, height: heightSquare))
        imageViewCoverSquare.image = UIImage(named: "deflaut_cover")
        imageViewCoverSquare.contentMode = .scaleAspectFill
        imageViewCoverSquare.round(10)
        imageViewCoverSquare.viewBorder(UIColor.secondary1(), width: 1)
        addSubview(imageViewCoverSquare)
        
        imageViewCoverRect = UIImageView(frame: CGRect(x: bounds.width - Margin.left * 2 - widthRect, y: topView.frame.maxY + Margin.top * 2, width: widthRect, height: heightRect))
        imageViewCoverRect.image = UIImage(named: "deflaut_cover")
        imageViewCoverRect.contentMode = .scaleAspectFill
        imageViewCoverRect.round(10)
        imageViewCoverRect.viewBorder(UIColor.secondary1(), width: 1)
        addSubview(imageViewCoverRect)
        
        labelSquare.formatSize(11)
        labelSquare.text = String.localize("直向")
        let widthLabel = StringHelper.getTextWidth(String.localize("直向"), height: heightLabel, font: labelSquare.font)
        labelSquare.frame = CGRect(x: imageViewCoverSquare.frame.maxX - widthLabel, y: imageViewCoverSquare.frame.maxY + 5, width: widthLabel, height: heightLabel)
        addSubview(labelSquare)
        
        labelRect.formatSize(11)
        labelRect.text = String.localize("直向")
        labelRect.frame = CGRect(x: imageViewCoverRect.frame.maxX - widthLabel, y: imageViewCoverRect.frame.maxY + 5, width: widthLabel, height: heightLabel)
        
        addSubview(labelRect)
        
    }
    
    func addBottomBorderWithColor(color: UIColor, andWidth borderWidth: CGFloat) {
        let border: UIView = UIView()
        border.backgroundColor = color
        border.autoresizingMask = [.FlexibleWidth, .FlexibleTopMargin]
        border.frame = CGRect(x:0, y: self.frame.height - borderWidth, width: self.frame.size.width, height: borderWidth)
        self.topView.addSubview(border)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
