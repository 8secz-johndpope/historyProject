//
//  CheckoutAddressSelectionCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/30/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CheckoutAddressSelectionCell: AddressSelectionCell {

    var bottomView : UIView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        bottomView = { () -> UIView in
            
            let iconImageViewWidth = CGFloat(11)
            let width = StringHelper.getTextWidth(String.localize("LB_CA_DEFAULT_ADDR"), height: AddressSelectionCell.LabelHeight, font: UIFont.systemFont(ofSize: CGFloat(AddressSelectionCell.FontSize))) + 5
            let view = UIView(frame:CGRect(x: checkboxButton.frame.maxX,y: receiverLabel.frame.maxY + AddressSelectionCell.VerticalPadding, width: width + iconImageViewWidth + AddressSelectionCell.VerticalPadding * 3, height: AddressSelectionCell.DefaultBottomViewHeight)
            )
            
            let imageView = UIImageView(frame:CGRect(x: 5, y: (AddressSelectionCell.DefaultBottomViewHeight - 8)/2, width: iconImageViewWidth, height: CGFloat(8)))
            imageView.image = UIImage(named:"ic_white_tick")
            imageView.contentMode = UIViewContentMode.scaleAspectFit
            view.addSubview(imageView)
            
            let label = UILabel(frame:CGRect(x: imageView.frame.maxX + 5, y: (AddressSelectionCell.DefaultBottomViewHeight - AddressSelectionCell.LabelHeight)/2, width: width, height: AddressSelectionCell.LabelHeight))
            label.formatSize(12)
            label.textColor = UIColor.white
            label.numberOfLines = 0
            label.text = String.localize("LB_CA_DEFAULT_ADDR")
            view.addSubview(label)
            
            view.backgroundColor = UIColor.secondary8()
            view.layer.cornerRadius = CGFloat(3)
            view.clipsToBounds = true
            return view
            } ()
        contentView.addSubview(bottomView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bottomHeight = (self.data?.isDefault ?? false) ? AddressSelectionCell.DefaultBottomViewHeight : 0
        
        bottomView.frame = CGRect(x: phoneLabel.frame.originX, y: frame.size.height - bottomHeight - AddressSelectionCell.TopPadding, width: bottomView.frame.width, height: bottomHeight)
        
        phoneLabel.frame = CGRect(x: phoneLabel.frame.originX, y: bottomView.frame.minY - AddressSelectionCell.LabelHeight - (bottomHeight == 0 ? 0 : AddressSelectionCell.VerticalPadding), width: phoneLabel.frame.width, height: AddressSelectionCell.LabelHeight)
        
        descriptionLabel.frame = CGRect(x: descriptionLabel.frame.originX, y: receiverLabel.frame.maxY + AddressSelectionCell.VerticalPadding, width: descriptionLabel.frame.width, height: phoneLabel.frame.minY - receiverLabel.frame.maxY - 2*AddressSelectionCell.VerticalPadding)
    }
    
    override func setDefaultAddress(_ isDefaultAddress: Bool) {
        super.setDefaultAddress(isDefaultAddress)
        if let data = self.data {
            bottomView.isHidden = !data.isDefault
        }
    }
}

