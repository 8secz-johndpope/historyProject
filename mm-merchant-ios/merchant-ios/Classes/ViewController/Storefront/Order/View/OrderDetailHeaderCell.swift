//
//  OrderDetailHeaderCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 24/8/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class OrderDetailHeaderCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderDetailHeaderCellID"
    static let DefaultHeight: CGFloat = 48
    static let HorizontalMargin: CGFloat = 15
    
    private var titleLabel = UILabel()
    private var topBorderView = UIView()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        titleLabel.formatSize(16)
        titleLabel.textColor = UIColor.secondary2()
        contentView.addSubview(titleLabel)
        
        topBorderView.backgroundColor = UIColor.secondary1()
        topBorderView.isHidden = true
        contentView.addSubview(topBorderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        titleLabel.frame = CGRect(
            x: OrderDetailHeaderCell.HorizontalMargin,
            y: frame.height - OrderDetailHeaderCell.DefaultHeight,
            width: frame.width - (OrderDetailHeaderCell.HorizontalMargin * 2),
            height: OrderDetailHeaderCell.DefaultHeight
        )
        
        topBorderView.frame = CGRect(x: 0, y: 0, width: frame.width, height: 1)
    }
    
    func setTitle(_ title: String) {
        titleLabel.text = title
    }
    
    func showTopBorderView(_ show: Bool) {
        topBorderView.isHidden = !show
    }
    
}
