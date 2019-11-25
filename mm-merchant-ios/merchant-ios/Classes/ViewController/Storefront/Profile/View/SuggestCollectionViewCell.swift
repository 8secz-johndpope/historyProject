//
//  SuggestCollectionViewCell.swift
//  merchant-ios
//
//  Created by Vu Dinh Trung on 4/24/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit

import PromiseKit
import ObjectMapper

class SuggestCollectionViewCell: ProductCell {
    
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        saleFontSize = CGFloat(12.0)
        retailFontSize = CGFloat(9.0)
        saleFont = UIFont.boldSystemFont(ofSize: saleFontSize)
        retailFont = UIFont.systemFont(ofSize: retailFontSize)
        nameLabel.formatSize(13)
        nameLabel.textAlignment = .center
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = .byTruncatingTail
        
        priceLabel.formatSize(16)
        priceLabel.textAlignment = .center
        priceLabel.numberOfLines = 1
        self.brandImageView.isHidden = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        nameLabel.frame = CGRect(x: bounds.minX + 5 , y: imageView.frame.maxY + 4  , width: bounds.width - 10 , height: 20)
        priceLabel.frame = CGRect(x: bounds.minX, y: nameLabel.frame.maxY + 4 , width: bounds.width, height: 20)
    }
    
    func setupDataBySku(_ skue: Sku) -> Void {
        setBrandImage(skue.brandImage)
        setProductImage(skue.productImage)
        fillPrice(skue.priceSale, priceRetail: skue.priceRetail, isSale: skue.isSale)
        nameLabel.text = skue.brandName
        heartImageView.isHidden = true		

    }
	
}
