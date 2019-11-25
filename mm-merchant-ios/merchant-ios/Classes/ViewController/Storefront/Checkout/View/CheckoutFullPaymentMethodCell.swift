//
//  CheckoutFullPaymentMethodCell.swift
//  merchant-ios
//
//  Created by Stephen Yuen on 22/12/2016.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

class CheckoutFullPaymentMethodCell: UICollectionViewCell {
    
    static let CellIdentifier = "CheckoutFullPaymentMethodCellID"
    
    private var paymentMethodImageView: UIImageView!
    private var paymentMethodLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        paymentMethodImageView = UIImageView()
        paymentMethodImageView.image = UIImage(named: "alipay_icon")
        addSubview(paymentMethodImageView)
        
        paymentMethodLabel = UILabel()
        paymentMethodLabel.text = String.localize("LB_CA_PAY_VIA_ALIPAY")
        paymentMethodLabel.formatSingleLine(15)
        paymentMethodLabel.textColor = UIColor.black
        addSubview(paymentMethodLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let imageDimension: CGFloat = 34
        let labelHeight: CGFloat = 22
        let marginLeft: CGFloat = 18
        let marginRight: CGFloat = 18
        
        paymentMethodImageView.frame = CGRect(x: marginLeft, y: (self.height - imageDimension) / 2, width: imageDimension, height: imageDimension)
        
        let paymentMethodLabelX = paymentMethodImageView.frame.maxX + 35
        paymentMethodLabel.frame = CGRect(x: paymentMethodLabelX, y: (self.height - labelHeight) / 2, width: self.width - paymentMethodLabelX - marginRight, height: labelHeight)
    }
}
