//
//  CouponViewCell.swift
//  merchant-ios
//
//  Created by Sang Nguyen on 7/6/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import Foundation

class CouponViewCell: UICollectionViewCell {
    
    static let CellIdentifier = "CouponViewCellID"
    
    var checkboxButton = UIButton(type: .custom)
    var couponNameLabel = UILabel()
    var priceLabel = UILabel()
    var separatorView = UIView()
    
    private final let  MarginLeftRight: CGFloat = 15
    private var coupon: Coupon?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        checkboxButton.config(
            normalImage: UIImage(named: "icon_checkbox_unchecked"),
            selectedImage: UIImage(named: "icon_checkbox_checked")
        )
        checkboxButton.sizeToFit()
        checkboxButton.isUserInteractionEnabled = false
        self.contentView.addSubview(checkboxButton)
        
        priceLabel.formatSize(15)
        priceLabel.textColor = UIColor.primary1()
        self.contentView.addSubview(priceLabel)
        
        couponNameLabel.formatSize(15)
        self.contentView.addSubview(couponNameLabel)
        
        separatorView.backgroundColor = UIColor.backgroundGray()
        self.contentView.addSubview(self.separatorView)
        self.separatorView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        checkboxButton.frame = CGRect(x: MarginLeftRight, y: (frame.height - checkboxButton.height) / 2, width: checkboxButton.width, height: checkboxButton.height)
        
        let width = StringHelper.getTextWidth(priceLabel.text ?? "", height: 20, font: priceLabel.font)
        
        priceLabel.frame = CGRect(x: checkboxButton.frame.maxX + MarginLeftRight, y: 0, width: width, height: frame.height)
        couponNameLabel.frame = CGRect(x: priceLabel.frame.maxX + MarginLeftRight / 2, y: 0, width: frame.width - (priceLabel.frame.maxX + MarginLeftRight + MarginLeftRight / 2), height: frame.height)
        separatorView.frame = CGRect(x: MarginLeftRight, y: frame.height - 1, width: frame.width - MarginLeftRight * 2, height: 1)
    }
    
    func setData(_ coupon: Coupon?) {
        self.coupon = coupon
        
        if let strongCoupon = coupon {
            self.couponNameLabel.text = strongCoupon.couponName
            
            if let price = strongCoupon.couponAmount.formatPrice() {
                self.priceLabel.text = price
            } else {
                self.priceLabel.text = ""
            }
            self.checkboxButton.isSelected = strongCoupon.isSelected
        } else {
            self.couponNameLabel.text = ""
            self.priceLabel.text = ""
            self.checkboxButton.isSelected = false
        }
        
        layoutSubviews()
    }
}
