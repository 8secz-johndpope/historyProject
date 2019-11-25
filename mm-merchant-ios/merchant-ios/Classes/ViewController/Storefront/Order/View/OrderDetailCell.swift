//
//  OrderDetailCell.swift
//  merchant-ios
//
//  Created by Gambogo on 4/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class OrderDetailCell: UICollectionViewCell {
    
    static let CellIdentifier = "OrderDetailCellID"
    
    static let HorizontalMargin: CGFloat = 15
    private static let PaddingContent: CGFloat = 8
    private static let LabelHeight: CGFloat = 20
    
    private var detailTitleLabel = UILabel()
    private var detailValueLabel = UILabel()
    private var bottomBorderView = UIView()
    
    var data: OrderDetailData? {
        didSet {
            detailTitleLabel.text = data?.title
            detailValueLabel.text = data?.value
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        
        detailTitleLabel.formatSize(10)
        detailTitleLabel.textColor = UIColor.secondary2()
        contentView.addSubview(detailTitleLabel)
        
        detailValueLabel.formatSize(13)
        detailValueLabel.textColor = UIColor.secondary2()
        detailValueLabel.numberOfLines = 0
        contentView.addSubview(detailValueLabel)
        
        bottomBorderView.backgroundColor = UIColor.secondary1()
        contentView.addSubview(bottomBorderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        detailTitleLabel.frame = CGRect(
            x: OrderDetailCell.HorizontalMargin,
            y: OrderDetailCell.PaddingContent,
            width: frame.width - (OrderDetailCell.HorizontalMargin * 2),
            height: OrderDetailCell.LabelHeight
        )
        
        detailValueLabel.frame = CGRect(
            x: OrderDetailCell.HorizontalMargin,
            y: detailTitleLabel.frame.maxY,
            width: frame.width - (OrderDetailCell.HorizontalMargin * 2),
            height: detailValueLabel.optimumHeight(width: frame.width - (OrderDetailCell.HorizontalMargin * 2))
        )
        
        bottomBorderView.frame = CGRect(x: OrderDetailCell.PaddingContent, y: frame.height - 1, width: frame.width - (OrderDetailCell.PaddingContent * 2), height: 1)
    }
    
    class func getCellHeight(text: String, width: CGFloat) -> CGFloat {
        let cellBasicHeight = (OrderDetailCell.PaddingContent * 2) + OrderDetailCell.LabelHeight
        
        let dummyLabel = UILabel()
        dummyLabel.formatSize(13)
        dummyLabel.numberOfLines = 0
        
        return cellBasicHeight + dummyLabel.optimumHeight(text: text, width: width)
    }
    
}
