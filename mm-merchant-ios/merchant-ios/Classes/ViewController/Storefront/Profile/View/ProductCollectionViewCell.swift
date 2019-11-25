//
//  ProductCollectionViewCell.swift
//  merchant-ios
//
//  Created by khanh.nguyen on 7/4/16.
//  Copyright © 2016 WWE & CO. All rights reserved.
//

import UIKit


protocol ProductCellDelegate: NSObjectProtocol {
    func didTapOnHeartIcon(_ cell: ProductCollectionViewCell)
}

class ProductCollectionViewCell: ProductCell {

//    var style: Style?
    weak var delegate: ProductCellDelegate?
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let maxWidht = bounds.width - 30
        imageView.frame = CGRect(x: bounds.minX  , y: bounds.minY, width: maxWidht , height: maxWidht * Constants.Ratio.ProductImageHeight)
        brandImageView.frame = CGRect(x: ((maxWidht - Constants.Value.BrandImageWidth) / 2), y: imageView.frame.maxY + 7 , width: Constants.Value.BrandImageWidth , height: Constants.Value.BrandImageHeight)
        nameLabel.frame = CGRect(x: bounds.minX + 25 , y: brandImageView.frame.maxY  , width: maxWidht - 50 , height: 40)
        priceLabel.frame = CGRect(x: bounds.minX, y: nameLabel.frame.maxY + 4 , width: maxWidht, height: 20)
        
        let sizeOfHeartImageView : CGSize = CGSize(width: 40, height: 40) //actually image size is 25x25, because transparent border is 25
        heartImageView.frame = CGRect(x: (imageView.frame.origin.x + imageView.frame.sizeWidth - 15), y: imageView.frame.maxY  - sizeOfHeartImageView.height + 15, width: sizeOfHeartImageView.width, height: sizeOfHeartImageView.height)
        heartImageView.contentMode = .scaleAspectFit
        
        heartImageView.isUserInteractionEnabled = true
        heartImageView.addGestureRecognizer(UITapGestureRecognizer(target:self, action:#selector(ProductCollectionViewCell.imageTapped)))
    }
    
    @objc func imageTapped(_ sender: Any) {
        delegate?.didTapOnHeartIcon(self)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        saleFontSize = CGFloat(12.0)
        retailFontSize = CGFloat(9.0)
        saleFont = UIFont.boldSystemFont(ofSize: saleFontSize)
        retailFont = UIFont.systemFont(ofSize: retailFontSize)
        self.nameLabel.formatSize(11)
        nameLabel.numberOfLines = 2
        
        self.heartImageView.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
}
