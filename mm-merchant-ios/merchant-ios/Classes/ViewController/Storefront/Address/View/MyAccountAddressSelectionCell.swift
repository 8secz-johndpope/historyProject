//
//  MyAccountAddressSelectionCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/30/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class MyAccountAddressSelectionCell: AddressSelectionCell {

    var defaultLabel: UILabel!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        defaultLabel = { () -> UILabel in
            let width = StringHelper.getTextWidth(String.localize("LB_CA_DEFAULT"), height: AddressSelectionCell.LabelHeight, font: UIFont.systemFont(ofSize: CGFloat(AddressSelectionCell.FontSize)))
            let label = UILabel(frame:CGRect(x: checkboxButton.frame.maxX,y: receiverLabel.frame.maxY + AddressSelectionCell.VerticalPadding,width: width,height: AddressSelectionCell.LabelHeight)
            )
            label.formatSize(AddressSelectionCell.FontSize)
            label.textColor = UIColor.grayTextColor()
            label.numberOfLines = 0
            label.text = String.localize("LB_CA_DEFAULT")
            return label
            } ()
        contentView.addSubview(defaultLabel)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        defaultLabel.centerY = checkboxButton.frame.center.y
        defaultLabel.frame.originX = checkboxButton.frame.maxX + AddressSelectionCell.HorizontalPadding
        
        receiverLabel.frame.originX = defaultLabel.frame.maxX + AddressSelectionCell.TopPadding * 3
        
        phoneLabel.frame.originX = receiverLabel.frame.originX
        
        let widthOfLabel = disclosureIndicatorImageView.frame.minX - (receiverLabel.frame.originX + AddressSelectionCell.VerticalPadding)
        descriptionLabel.frame.originX = receiverLabel.frame.originX
        descriptionLabel.frame.sizeWidth = widthOfLabel
        
    }
}
