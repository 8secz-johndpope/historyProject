//
//  CommonViewItemCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 18/3/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CommonViewItemCell: UICollectionViewCell {
    
    static let CellIdentifier = "CommonViewItemCellID"
    static let DefaultHeight: CGFloat = 45
    
    enum CellStyle: Int {
        case normal = 0,
        alert
    }
    
    var itemLabel = UILabel()
    var itemValue = UILabel()
    private var disclosureIndicatorImageView = UIImageView()
    private var topBorderView = UIView()
    private var bottomBorderView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        self.clipsToBounds = true
        
        itemLabel.formatSize(14)
        addSubview(itemLabel)
        
        disclosureIndicatorImageView.image = UIImage(named: "filter_right_arrow")
        addSubview(disclosureIndicatorImageView)
        
        itemValue.formatSize(14)
        addSubview(itemValue)
        
        topBorderView.backgroundColor = UIColor.secondary1()
        topBorderView.isHidden = true
        addSubview(topBorderView)
        
        bottomBorderView.backgroundColor = UIColor.secondary1()
        addSubview(bottomBorderView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let marginLeft: CGFloat = 20
        let labelHeight: CGFloat = 42
        
        topBorderView.frame = CGRect(x: bounds.minX, y: 0, width: bounds.width, height: 1)
        bottomBorderView.frame = CGRect(x: bounds.minX, y: bounds.maxY - 1, width: bounds.width, height: 1)
        disclosureIndicatorImageView.frame = CGRect(x: bounds.maxX - 35 , y: bounds.midY - (disclosureIndicatorImageView.image!.size.height / 2) , width: disclosureIndicatorImageView.image!.size.width, height: disclosureIndicatorImageView.image!.size.height)
        
        itemLabel.frame = CGRect(
            x: marginLeft,
            y: bounds.midY - (labelHeight / 2),
            width: (frame.sizeWidth / 2) - marginLeft,
            height: labelHeight
        )
        
        itemValue.frame = CGRect(
            x: bounds.maxX - (frame.sizeWidth / 2) - disclosureIndicatorImageView.width,
            y: bounds.midY - (labelHeight / 2),
            width: (frame.sizeWidth / 2) - disclosureIndicatorImageView.width - marginLeft,
            height: labelHeight
        )
        itemValue.textAlignment = .right
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setCellStyle(_ cellStyle: CellStyle) {
        itemLabel.formatSize(14)
        
        if cellStyle == .alert {
            itemLabel.textColor = UIColor.primary1()
        } else {
            itemLabel.textColor = UIColor.black
        }
    }
    
    func showTopBorder(_ isShow: Bool) {
        topBorderView.isHidden = !isShow
    }
    
    func showBottomBorder(_ isShow: Bool) {
        bottomBorderView.isHidden = !isShow
    }
    
    func showDisclosureIndicator(_ isShow: Bool) {
        disclosureIndicatorImageView.isHidden = !isShow
    }
}
