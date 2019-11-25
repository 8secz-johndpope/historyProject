//
//  HashTagHeaderView.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 9/7/17.
//  Copyright © 2017 WWE & CO. All rights reserved.
//

import UIKit

protocol HashTagHeaderDelegate : NSObjectProtocol {
    func hashtagHeaderClickOnRecycleButton()
}

class HashTagHeaderView: UICollectionReusableView {

    
    static var ViewIdentifier = "ViewIdentifier"
    var leftLabel = UILabel()
    var iconImageView = UIImageView()
    weak var delegate: HashTagHeaderDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        leftLabel.applyFontSize(12, isBold: false)
        leftLabel.text = String.localize("LB_CA_CLAIM_MERCHANT_COUPON")
        leftLabel.textColor = UIColor.init(hexString: "#D5D5D5")
        self.addSubview(leftLabel)
        
        iconImageView.image = UIImage(named: "icon_clear")
        iconImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(HashTagHeaderView.clickOnRecycleButton)))
        iconImageView.isUserInteractionEnabled = true
        self.addSubview(iconImageView)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let labelHeight = self.bounds.sizeHeight
        let width = StringHelper.getTextWidth(leftLabel.text ?? "", height: labelHeight, font: leftLabel.font)
        leftLabel.frame = CGRect(x: Margin.left, y: 0, width: width, height: labelHeight)
        
        let size = CGSize(width: 12, height: 12)
        iconImageView.frame = CGRect(x: self.bounds.sizeWidth - size.width - Margin.left, y: (self.bounds.sizeHeight - size.height)/2, width: size.width, height: size.height)
        
    }
    
    @objc func clickOnRecycleButton() {
        delegate?.hashtagHeaderClickOnRecycleButton()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
